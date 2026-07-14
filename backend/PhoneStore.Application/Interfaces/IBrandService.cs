using PhoneStore.Application.DTOs.Brand;

namespace PhoneStore.Application.Interfaces;

public interface IBrandService
{
    Task<List<BrandDto>> GetAllBrandsAsync();
    Task<BrandDto> GetBrandByIdAsync(string id);
    Task<BrandDto> CreateBrandAsync(CreateBrandDto dto);
    Task<BrandDto> UpdateBrandAsync(string id, UpdateBrandDto dto);
    Task DeleteBrandAsync(string id);
}
