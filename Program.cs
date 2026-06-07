using BlogAPI.DatabaseContext;
using BlogAPI.DataTransfer;
using BlogAPI.Entities;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<BlogContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("BlogContextDatabase")));

var app = builder.Build();

app.MapPost("/posts", async (PostRequest post, BlogContext db) =>
{
    var newPost = new Post
    {
        Author = post.Author,
        Content = post.Content,
        Description = post.Description,
        Published = DateTimeOffset.UtcNow,
        Slug = string.Join("-", post.Title.ToLowerInvariant().Split(" ")),
        Tags = post.Tags,
        Title = post.Title
    };

    db.Posts.Add(newPost);
    await db.SaveChangesAsync();

    return TypedResults.Created(
        $"/posts/{newPost.Id}",
        newPost
    );
});

app.MapGet("/posts", async (BlogContext db) =>
    await db.Posts.ToListAsync());

app.Run();
