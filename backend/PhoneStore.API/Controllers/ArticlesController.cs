using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Article;
using PhoneStore.Application.Interfaces;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ArticlesController : ControllerBase
{
    private readonly IArticleService _articleService;

    public ArticlesController(IArticleService articleService)
    {
        _articleService = articleService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<IEnumerable<ArticleDto>>>> GetArticles()
    {
        var articles = await _articleService.GetAllAsync();
        return Ok(ApiResponse<IEnumerable<ArticleDto>>.SuccessResponse(articles));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<ArticleDto>>> GetArticle(string id)
    {
        var article = await _articleService.GetByIdAsync(id);
        if (article == null) return NotFound(ApiResponse<ArticleDto>.ErrorResponse("Article not found"));
        return Ok(ApiResponse<ArticleDto>.SuccessResponse(article));
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<ArticleDto>>> CreateArticle(CreateArticleDto dto)
    {
        var authorId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var authorName = User.FindFirstValue(ClaimTypes.Name) ?? "Staff";
        var article = await _articleService.CreateAsync(dto, authorId, authorName);
        return Ok(ApiResponse<ArticleDto>.SuccessResponse(article, "Created successfully"));
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateArticle(string id, UpdateArticleDto dto)
    {
        var success = await _articleService.UpdateAsync(id, dto);
        if (!success) return NotFound(ApiResponse<bool>.ErrorResponse("Article not found"));
        return Ok(ApiResponse<bool>.SuccessResponse(true, "Updated successfully"));
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteArticle(string id)
    {
        var success = await _articleService.DeleteAsync(id);
        if (!success) return NotFound(ApiResponse<bool>.ErrorResponse("Article not found"));
        return Ok(ApiResponse<bool>.SuccessResponse(true, "Deleted successfully"));
    }
}

