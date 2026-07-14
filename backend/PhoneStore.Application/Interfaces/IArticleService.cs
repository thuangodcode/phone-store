using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Article;

namespace PhoneStore.Application.Interfaces;

public interface IArticleService
{
    Task<IEnumerable<ArticleDto>> GetAllAsync();
    Task<ArticleDto?> GetByIdAsync(string id);
    Task<ArticleDto> CreateAsync(CreateArticleDto dto, string authorId, string authorName);
    Task<bool> UpdateAsync(string id, UpdateArticleDto dto);
    Task<bool> DeleteAsync(string id);
}

