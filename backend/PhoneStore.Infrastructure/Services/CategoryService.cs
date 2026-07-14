using AutoMapper;
using PhoneStore.Application.DTOs.Category;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Interfaces;

namespace PhoneStore.Infrastructure.Services;

public class CategoryService : ICategoryService
{
    private readonly IRepository<Category> _categoryRepository;
    private readonly IMapper _mapper;

    public CategoryService(IRepository<Category> categoryRepository, IMapper mapper)
    {
        _categoryRepository = categoryRepository;
        _mapper = mapper;
    }

    public async Task<List<CategoryDto>> GetAllCategoriesAsync()
    {
        var categories = await _categoryRepository.GetAllAsync();
        return _mapper.Map<List<CategoryDto>>(categories);
    }

    public async Task<CategoryDto> GetCategoryByIdAsync(string id)
    {
        var category = await _categoryRepository.GetByIdAsync(id);
        if (category == null)
            throw new Exception("Category not found.");
        return _mapper.Map<CategoryDto>(category);
    }

    public async Task<CategoryDto> CreateCategoryAsync(CreateCategoryDto dto)
    {
        var category = _mapper.Map<Category>(dto);
        category.CreatedAt = DateTime.UtcNow;
        await _categoryRepository.CreateAsync(category);
        return _mapper.Map<CategoryDto>(category);
    }

    public async Task<CategoryDto> UpdateCategoryAsync(string id, UpdateCategoryDto dto)
    {
        var category = await _categoryRepository.GetByIdAsync(id);
        if (category == null)
            throw new Exception("Category not found.");

        category.Name = dto.Name;
        category.Description = dto.Description;
        category.IsActive = dto.IsActive;

        await _categoryRepository.UpdateAsync(id, category);
        return _mapper.Map<CategoryDto>(category);
    }

    public async Task DeleteCategoryAsync(string id)
    {
        var category = await _categoryRepository.GetByIdAsync(id);
        if (category == null)
            throw new Exception("Category not found.");
        await _categoryRepository.DeleteAsync(id);
    }
}
