using System.ComponentModel.DataAnnotations;
namespace PhoneStore.Application.DTOs.Article;

public class ArticleDto
{
    public string Id { get; set; } = null!;
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string ProductUrl { get; set; } = string.Empty;
    public string AuthorId { get; set; } = null!;
    public string AuthorName { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class CreateArticleDto
{
    [Required] public string Title { get; set; } = string.Empty;
    [Required] public string Content { get; set; } = string.Empty;
    public string ImageUrl { get; set; } = string.Empty;
    public string ProductUrl { get; set; } = string.Empty;
}

public class UpdateArticleDto : CreateArticleDto {}

