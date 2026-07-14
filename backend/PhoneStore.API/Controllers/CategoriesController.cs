using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Category;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Enums;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CategoriesController : ControllerBase
{
    private readonly ICategoryService _categoryService;

    public CategoriesController(ICategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<CategoryDto>>>> GetAllCategories()
    {
        var result = await _categoryService.GetAllCategoriesAsync();
        return Ok(ApiResponse<List<CategoryDto>>.SuccessResponse(result));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<CategoryDto>>> GetCategoryById(string id)
    {
        var result = await _categoryService.GetCategoryByIdAsync(id);
        return Ok(ApiResponse<CategoryDto>.SuccessResponse(result));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<CategoryDto>>> CreateCategory([FromBody] CreateCategoryDto dto)
    {
        var result = await _categoryService.CreateCategoryAsync(dto);
        return CreatedAtAction(nameof(GetCategoryById), new { id = result.Id }, ApiResponse<CategoryDto>.SuccessResponse(result, "Category created successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<CategoryDto>>> UpdateCategory(string id, [FromBody] UpdateCategoryDto dto)
    {
        var result = await _categoryService.UpdateCategoryAsync(id, dto);
        return Ok(ApiResponse<CategoryDto>.SuccessResponse(result, "Category updated successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse>> DeleteCategory(string id)
    {
        await _categoryService.DeleteCategoryAsync(id);
        return Ok(ApiResponse.SuccessResponse("Category deleted successfully"));
    }
}
