using System.Globalization;
using BlogAPI.DatabaseContext;
using BlogAPI.DataTransfer;
using BlogAPI.DataTransfer.QueryParameters;
using BlogAPI.Entities;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<BlogContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("BlogContextDatabase")));

builder.Services.AddProblemDetails();

builder.Services.AddValidation();

var app = builder.Build();

app.UseStatusCodePages();

app.MapPost("/posts", async (PostRequest post, BlogContext db) =>
{
    var newPost = new Post
    {
        Author = post.Author,
        Content = post.Content,
        Description = post.Description,
        Published = post.Published,
        Slug = await GenerateSlugAsync(post.Title, db),
        Tags = await GetCombinedTagsAsync(post.Tags, db),
        Title = post.Title
    };

    db.Posts.Add(newPost);
    await db.SaveChangesAsync();

    return TypedResults.Created(
        $"/posts/{newPost.Id}",
        new PostResponse(newPost)
    );
});

app.MapGet("/posts", async Task<Results<Ok<PagedPostResponse>, BadRequest<string>, ValidationProblem>> (
    [AsParameters] GetAllPostsQueryParameters queryParams,
    BlogContext db
) =>
{
    var query = db.Posts
        .AsNoTracking()
        .AsQueryable();

    if (!string.IsNullOrWhiteSpace(queryParams.FromDate))
    {
        var parsedFromDateResult = DateTime.TryParseExact(
            queryParams.FromDate,
            "yyyy-MM-dd",
            CultureInfo.InvariantCulture,
            DateTimeStyles.None,
            out var parsedFromDate
        );

        if (!parsedFromDateResult)
        {
            return TypedResults.BadRequest("The format of `fromDate` is invalid. The correct format is 'yyyy-MM-dd'.");
        }

        query = query.Where(p => p.Published >= parsedFromDate);
    }

    if (queryParams.Tags is not null)
    {
        var normalizedTags = queryParams.Tags
            .Split(",")
            .Where(t => !string.IsNullOrWhiteSpace(t))
            .Select(t => t.Trim().ToLowerInvariant())
            .Distinct()
            .ToList();

        if (normalizedTags.Count > 0)
        {
            query = query.Where(p => p.Tags.Any(t => normalizedTags.Contains(t.Name)));
        }
    }

    var limit = queryParams.Limit ?? 30;
    var offset = queryParams.Offset ?? 0;

    if (limit < 1)
    {
        return TypedResults.ValidationProblem(
            new Dictionary<string, string[]>
            {
                ["limit"] = ["The limit parameter must be greater than or equal to 1"]
            }
        );
    }

    if (offset < 0)
    {
        return TypedResults.ValidationProblem(
            new Dictionary<string, string[]>
            {
                ["offset"] = ["The offset parameter must be greater than or equal to 0"]
            }
        );
    }

    var total = await query.CountAsync();

    var posts = await query
        .OrderByDescending(p => p.Published)
        .ThenByDescending(p => p.Id)
        .Skip(offset)
        .Take(limit)
        .Select(PostResponse.Projection)
        .ToListAsync();

    return TypedResults.Ok(new PagedPostResponse
    {
        Limit = limit,
        Offset = offset,
        Posts = posts,
        Total = total
    });
});

app.MapGet("/posts/{id}", async Task<Results<Ok<PostResponse>, NotFound>> (int id, BlogContext db) =>
{
    var post = await db.Posts
        .Where(p => p.Id == id)
        .Select(PostResponse.Projection)
        .FirstOrDefaultAsync();

    if (post is null)
    {
        return TypedResults.NotFound();
    }

    return TypedResults.Ok(post);
});

app.MapPut("/posts/{id}", async Task<Results<Ok<PostResponse>, NotFound>> (int id, PostRequest newPost, BlogContext db) =>
{
    var post = await db.Posts
        .Where(p => p.Id == id)
        .Include(p => p.Tags)
        .FirstOrDefaultAsync();

    if (post is null)
    {
        return TypedResults.NotFound();
    }

    post.Tags.Clear();

    post.Author = newPost.Author;
    post.Content = newPost.Content;
    post.Description = newPost.Description;
    post.Tags = await GetCombinedTagsAsync(newPost.Tags, db);
    post.Title = newPost.Title;

    await db.SaveChangesAsync();

    return TypedResults.Ok(new PostResponse(post));
});

app.MapDelete("/posts/{id}", async Task<Results<NoContent, NotFound>> (int id, BlogContext db) =>
{
    var post = await db.Posts.FindAsync(id);

    if (post is null)
    {
        return TypedResults.NotFound();
    }

    db.Posts.Remove(post);
    await db.SaveChangesAsync();

    return TypedResults.NoContent();
});

static async Task<List<Tag>> GetCombinedTagsAsync(ICollection<string> tags, BlogContext db)
{
    var normalizedTags = tags
        .Where(t => !string.IsNullOrWhiteSpace(t))
        .Select(t => t.Trim().ToLowerInvariant())
        .Distinct()
        .ToList();

    var existingTags = await db.Tags
        .Where(t => normalizedTags.Contains(t.Name))
        .ToDictionaryAsync(t => t.Name);

    return [.. normalizedTags.Select(t => existingTags.GetValueOrDefault(t) ?? new Tag { Name = t })];
}

static async Task<string> GenerateSlugAsync(string title, BlogContext db)
{
    var baseSlug = string.Join("-", title.ToLowerInvariant().Split(" "));
    var slug = baseSlug;
    var suffix = 2;

    while (await db.Posts.AnyAsync(p => p.Slug == slug))
    {
        slug = $"{baseSlug}-{suffix}";
        suffix++;
    }

    return slug;
}

app.Run();
