using AutoMapper;
using MongoDB.Driver;
using PhoneStore.Application.DTOs.Article;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class ArticleService : IArticleService
{
    private readonly MongoDbContext _context;
    private readonly IMapper _mapper;

    public ArticleService(MongoDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<IEnumerable<ArticleDto>> GetAllAsync()
    {
        var articles = await _context.Articles.Find(_ => true).SortByDescending(a => a.CreatedAt).ToListAsync();
        return _mapper.Map<IEnumerable<ArticleDto>>(articles);
    }

    public async Task<ArticleDto?> GetByIdAsync(string id)
    {
        var article = await _context.Articles.Find(a => a.Id == id).FirstOrDefaultAsync();
        return article == null ? null : _mapper.Map<ArticleDto>(article);
    }

    public async Task<ArticleDto> CreateAsync(CreateArticleDto dto, string authorId, string authorName)
    {
        var article = _mapper.Map<Article>(dto);
        article.AuthorId = authorId;
        article.AuthorName = authorName;
        article.CreatedAt = DateTime.UtcNow;
        article.UpdatedAt = DateTime.UtcNow;

        await _context.Articles.InsertOneAsync(article);
        return _mapper.Map<ArticleDto>(article);
    }

    public async Task<bool> UpdateAsync(string id, UpdateArticleDto dto)
    {
        var update = Builders<Article>.Update
            .Set(a => a.Title, dto.Title)
            .Set(a => a.Content, dto.Content)
            .Set(a => a.ImageUrl, dto.ImageUrl)
            .Set(a => a.ProductUrl, dto.ProductUrl)
            .Set(a => a.UpdatedAt, DateTime.UtcNow);

        var result = await _context.Articles.UpdateOneAsync(a => a.Id == id, update);
        return result.ModifiedCount > 0;
    }

    public async Task<bool> DeleteAsync(string id)
    {
        var result = await _context.Articles.DeleteOneAsync(a => a.Id == id);
        return result.DeletedCount > 0;
    }
}

