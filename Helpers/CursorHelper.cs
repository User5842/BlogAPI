using System.Diagnostics.CodeAnalysis;
using System.Text.Json;
using BlogAPI.DataTransfer;
using BlogAPI.DataTransfer.QueryParameters;
using Microsoft.AspNetCore.WebUtilities;

namespace BlogAPI.Helpers;

public static class CursorHelper
{
    public static string? GenerateCursor(List<PostResponse> posts, int limit)
    {
        if (posts.Count <= limit)
        {
            return null;
        }

        var cursorBytes = JsonSerializer.SerializeToUtf8Bytes(
            new PostCursor { Id = posts[limit - 1].Id }
        );
        return WebEncoders.Base64UrlEncode(cursorBytes);
    }

    public static bool TryParseCursor(string cursor, [NotNullWhen(true)] out PostCursor? postCursor)
    {
        postCursor = null;

        try
        {
            var cursorDecoded = WebEncoders.Base64UrlDecode(cursor);
            postCursor = JsonSerializer.Deserialize<PostCursor>(cursorDecoded);
        }
        catch
        {
            return false;
        }

        if (postCursor is null || postCursor.Id < 0) return false;

        return true;
    }
}