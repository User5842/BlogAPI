using BlogAPI.Entities;
using Microsoft.EntityFrameworkCore;

namespace BlogAPI.DatabaseContext;

public sealed class BlogContext(DbContextOptions<BlogContext> options) : DbContext(options)
{
    public DbSet<Post> Posts { get; set; }
    public DbSet<Tag> Tags { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Tag>()
            .HasIndex(t => t.Name)
            .IsUnique();

        base.OnModelCreating(modelBuilder);
    }
}