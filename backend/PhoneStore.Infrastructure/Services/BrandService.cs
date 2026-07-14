using AutoMapper;
using PhoneStore.Application.DTOs.Brand;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Interfaces;

namespace PhoneStore.Infrastructure.Services;

public class BrandService : IBrandService
{
    private readonly IRepository<Brand> _brandRepository;
    private readonly IMapper _mapper;

    public BrandService(IRepository<Brand> brandRepository, IMapper mapper)
    {
        _brandRepository = brandRepository;
        _mapper = mapper;
    }

    public async Task<List<BrandDto>> GetAllBrandsAsync()
    {
        var brands = await _brandRepository.GetAllAsync();
        return _mapper.Map<List<BrandDto>>(brands);
    }

    public async Task<BrandDto> GetBrandByIdAsync(string id)
    {
        var brand = await _brandRepository.GetByIdAsync(id);
        if (brand == null)
            throw new Exception("Brand not found.");
        return _mapper.Map<BrandDto>(brand);
    }

    public async Task<BrandDto> CreateBrandAsync(CreateBrandDto dto)
    {
        var brand = _mapper.Map<Brand>(dto);
        brand.CreatedAt = DateTime.UtcNow;
        await _brandRepository.CreateAsync(brand);
        return _mapper.Map<BrandDto>(brand);
    }

    public async Task<BrandDto> UpdateBrandAsync(string id, UpdateBrandDto dto)
    {
        var brand = await _brandRepository.GetByIdAsync(id);
        if (brand == null)
            throw new Exception("Brand not found.");

        brand.Name = dto.Name;
        brand.Logo = dto.Logo;
        brand.IsActive = dto.IsActive;

        await _brandRepository.UpdateAsync(id, brand);
        return _mapper.Map<BrandDto>(brand);
    }

    public async Task DeleteBrandAsync(string id)
    {
        var brand = await _brandRepository.GetByIdAsync(id);
        if (brand == null)
            throw new Exception("Brand not found.");
        await _brandRepository.DeleteAsync(id);
    }
}
