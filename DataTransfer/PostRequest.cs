namespace BlogAPI.DataTransfer;

public sealed class PostRequest
{
    public required string Author { get; set; }
    public required string Content { get; set; }
    public string? Description { get; set; }
    public string? Summary { get; set; }
    public required ICollection<string> Tags { get; set; }
    public required string Title { get; set; }
}