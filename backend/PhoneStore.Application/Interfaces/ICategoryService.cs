using PhoneStore.Application.DTOs.Category;

namespace PhoneStore.Application.Interfaces;

public interface ICategoryService
{
    Task<List<CategoryDto>> GetAllCategoriesAsync();
    Task<CategoryDto> GetCategoryByIdAsync(string id);
    Task<CategoryDto> CreateCategoryAsync(CreateCategoryDto dto);
    Task<CategoryDto> UpdateCategoryAsync(string id, UpdateCategoryDto dto);
    Task DeleteCategoryAsync(string id);
}
