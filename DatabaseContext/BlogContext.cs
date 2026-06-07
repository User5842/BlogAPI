using BlogAPI.Entities;
using Microsoft.EntityFrameworkCore;

namespace BlogAPI.DatabaseContext;

public sealed class BlogContext(DbContextOptions<BlogContext> options) : DbContext(options)
{
    public DbSet<Post> Posts { get; set; }
}