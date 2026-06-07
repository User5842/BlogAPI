# BlogAPI

## Functional requirements

- [x] Create a new post
- [] Retrieve a single post
- [] Retrieve all posts
- [] Update a single post
- [] Delete a single post

## Entities

### Post

```
Author: string
Content: string
Description: string
Id: int
Published: DateTimeOffset
Summary: string
Slug: string
Tags: IList<string>
Title: string
```

### Tag

```
Id: int
Name: string
```

## Data Transfer Objects

### CreatePostRequest

```
Author: string
Content: string
Description: string
Summary: string
Tags: IList<string>
Title: string
```

### CreatedPostResponse

```
Author: string
Content: string
Description: string
Id: int
Published: DateTimeOffset
Summary: string
Slug: string
Tags: IList<string>
Title: string
```

## API Endpoints

### Create a post

```json
POST /posts HTTP/1.1
Accept: application/json
Host: localhost

{
    "Author": "Rafael Negron",
    "Content": "Sample content",
    "Description": "Sample description",
    "Summary": "Sample summary",
    "Tags": ["general"],
    "Title": "Sample title"
}
```

```json
HTTP/1.1 201 Created
Content-Type: application/json
Location: /posts/1

{
    "Author": "Rafael Negron",
    "Content": "Sample content",
    "Description": "Sample description",
    "Id": 1,
    "Published": "06/04/2026",
    "Slug": "sample-title",
    "Summary": "Sample summary",
    "Tags": ["general"],
    "Title": "Sample title"
}
```

### Retrieve a single post

```json
GET /posts/1 HTTP/1.1
Accept: posts/1
Host: localhost

200 OK HTTP/1.1
Content-Type: application/json

{
    "Author": "Rafael Negron",
    "Content": "Sample content",
    "Description": "Sample description",
    "Id": 1,
    "Published": "06/04/2026",
    "Slug": "sample-title",
    "Summary": "Sample summary",
    "Tags": ["general"],
    "Title": "Sample title"
}
```

```json
404 Not Found HTTP/1.1
Content-Type: application/problem+json

{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.5",
  "title": "Not Found",
  "status": 404,
  "detail": "The post with the specified identifier was not found",
  "instance": "GET /posts/1"
}
```

### Retrieve all posts

```json
GET /posts HTTP/1.1
Accept: application/json
Host: localhost

200 OK HTTP/1.1
Content-Type: application/json

[
    {
        "Author": "Rafael Negron",
        "Content": "Sample content",
        "Description": "Sample description",
        "Id": 1,
        "Published": "06/04/2026",
        "Slug": "sample-title",
        "Summary": "Sample summary",
        "Tags": ["general"],
        "Title": "Sample title"
    }
]
```

### Update a single post

```json
PUT /posts/1 HTTP/1.1
Accept: application/json
Host: localhost

{
    "Author": "Rafael Negron",
    "Content": "Updated content",
    "Description": "Updated description",
    "Summary": "Updated summary",
    "Tags": ["general", "code", "finance"],
    "Title": "Updated title"
}
```

```json
200 OK HTTP/1.1
Content-Type: application/json

{
    "Author": "Rafael Negron",
    "Content": "Updated content",
    "Description": "Updated description",
    "Id": 1,
    "Published": "06/04/2026",
    "Slug": "updated-title",
    "Summary": "Updated summary",
    "Tags": ["general"],
    "Title": "Updated title"
}
```

### Delete a single post

```json
DELETE /posts/1 HTTP/1.1
Accept: application/json
Host: localhost

HTTP/1.1 204 No Content

HTTP/1.1 404 Not Found
```