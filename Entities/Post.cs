namespace BlogAPI.Entities;

public sealed class Post
{
    public required string Author { get; set; }
    public required string Content { get; set; }
    public string? Description { get; set; }
    public int Id { get; set; }
    public required DateTime Published { get; set; }
    public required string Slug { get; set; }
    public string? Summary { get; set; }
    public ICollection<Tag> Tags { get; set; } = [];
    public required string Title { get; set; }
}