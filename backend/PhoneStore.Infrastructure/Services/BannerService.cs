using PhoneStore.Application.DTOs.Banner;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using MongoDB.Driver;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class BannerService : IBannerService
{
    private readonly MongoDbContext _context;

    public BannerService(MongoDbContext context)
    {
        _context = context;
    }

    public async Task<List<BannerDto>> GetAllBannersAsync()
    {
        var banners = await _context.Banners.Find(_ => true).SortByDescending(x => x.CreatedAt).ToListAsync();
        return banners.Select(b => new BannerDto
        {
            Id = b.Id,
            Title = b.Title,
            ImageUrl = b.ImageUrl,
            IsActive = b.IsActive,
            CreatedAt = b.CreatedAt
        }).ToList();
    }

    public async Task<BannerDto?> GetActiveBannerAsync()
    {
        var banner = await _context.Banners.Find(b => b.IsActive).SortByDescending(x => x.CreatedAt).FirstOrDefaultAsync();
        if (banner == null) return null;
        
        return new BannerDto
        {
            Id = banner.Id,
            Title = banner.Title,
            ImageUrl = banner.ImageUrl,
            IsActive = banner.IsActive,
            CreatedAt = banner.CreatedAt
        };
    }

    public async Task<BannerDto> GetBannerByIdAsync(string id)
    {
        var banner = await _context.Banners.Find(b => b.Id == id).FirstOrDefaultAsync();
        if (banner == null) throw new Exception("Banner not found");
        
        return new BannerDto
        {
            Id = banner.Id,
            Title = banner.Title,
            ImageUrl = banner.ImageUrl,
            IsActive = banner.IsActive,
            CreatedAt = banner.CreatedAt
        };
    }

    public async Task<BannerDto> CreateBannerAsync(CreateBannerDto dto)
    {
        // If creating active, deactivate others
        if (dto.IsActive)
        {
            await DeactivateAllBannersAsync();
        }

        var banner = new Banner
        {
            Title = dto.Title,
            ImageUrl = dto.ImageUrl,
            IsActive = dto.IsActive,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        await _context.Banners.InsertOneAsync(banner);
        
        return await GetBannerByIdAsync(banner.Id);
    }

    public async Task<BannerDto> UpdateBannerAsync(string id, UpdateBannerDto dto)
    {
        var banner = await _context.Banners.Find(b => b.Id == id).FirstOrDefaultAsync();
        if (banner == null) throw new Exception("Banner not found");

        if (dto.IsActive && !banner.IsActive)
        {
            await DeactivateAllBannersAsync();
        }

        banner.Title = dto.Title;
        banner.ImageUrl = dto.ImageUrl;
        banner.IsActive = dto.IsActive;
        banner.UpdatedAt = DateTime.UtcNow;

        await _context.Banners.ReplaceOneAsync(b => b.Id == id, banner);
        return await GetBannerByIdAsync(id);
    }

    public async Task<bool> DeleteBannerAsync(string id)
    {
        var result = await _context.Banners.DeleteOneAsync(b => b.Id == id);
        return result.DeletedCount > 0;
    }

    public async Task<BannerDto> ToggleBannerStatusAsync(string id)
    {
        var banner = await _context.Banners.Find(b => b.Id == id).FirstOrDefaultAsync();
        if (banner == null) throw new Exception("Banner not found");

        if (!banner.IsActive)
        {
            await DeactivateAllBannersAsync();
        }

        banner.IsActive = !banner.IsActive;
        banner.UpdatedAt = DateTime.UtcNow;
        await _context.Banners.ReplaceOneAsync(b => b.Id == id, banner);
        
        return await GetBannerByIdAsync(id);
    }

    private async Task DeactivateAllBannersAsync()
    {
        var update = Builders<Banner>.Update.Set(b => b.IsActive, false);
        await _context.Banners.UpdateManyAsync(b => b.IsActive, update);
    }
}
