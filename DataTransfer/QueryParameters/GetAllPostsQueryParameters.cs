namespace BlogAPI.DataTransfer.QueryParameters;

public sealed class GetAllPostsQueryParameters
{
    public string? FromDate { get; set; }
    public int? Limit { get; set; }
    public int? Offset { get; set; }
    public string? Tags { get; set; }
}