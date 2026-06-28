namespace BlogAPI.DataTransfer;

public sealed class PagedPostResponse
{
    public required string? Cursor { get; set; }
    public required int Limit { get; set; }
    public required List<PostResponse> Posts { get; set; }
    public required int Total { get; set; }
}