namespace BlogAPI.DataTransfer.QueryParameters;

public sealed class GetAllPostsQueryParameters
{
    public string? Cursor { get; set; }
    public string? FromDate { get; set; }
    public int? Limit { get; set; }
    public string? Tags { get; set; }
}