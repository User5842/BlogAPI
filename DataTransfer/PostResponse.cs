using System.Diagnostics.CodeAnalysis;
using BlogAPI.Entities;

namespace BlogAPI.DataTransfer;

public sealed partial class PostResponse
{
    public required string Author { get; set; }
    public required string Content { get; set; }
    public string? Description { get; set; }
    public int Id { get; set; }
    public required DateTimeOffset Published { get; set; }
    public required string Slug { get; set; }
    public string? Summary { get; set; }
    public ICollection<string> Tags { get; set; } = [];
    public required string Title { get; set; }
}