using System.Diagnostics.CodeAnalysis;
using System.Linq.Expressions;
using BlogAPI.Entities;

namespace BlogAPI.DataTransfer;

public sealed partial class PostResponse
{
    public PostResponse() { }

    [SetsRequiredMembers]
    public PostResponse(Post post)
    {
        Author = post.Author;
        Content = post.Content;
        Description = post.Description;
        Id = post.Id;
        Published = post.Published;
        Slug = post.Slug;
        Summary = post.Summary;
        Tags = [.. post.Tags.Select(t => t.Name)];
        Title = post.Title;
    }

    public static Expression<Func<Post, PostResponse>> Projection = post =>
        new PostResponse
        {
            Author = post.Author,
            Content = post.Content,
            Description = post.Description,
            Id = post.Id,
            Published = post.Published,
            Slug = post.Slug,
            Summary = post.Summary,
            Tags = post.Tags.Select(t => t.Name).ToList(),
            Title = post.Title
        };
}