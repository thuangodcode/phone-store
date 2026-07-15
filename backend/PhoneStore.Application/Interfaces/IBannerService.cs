using PhoneStore.Application.DTOs.Banner;

namespace PhoneStore.Application.Interfaces;

public interface IBannerService
{
    Task<List<BannerDto>> GetAllBannersAsync();
    Task<BannerDto?> GetActiveBannerAsync();
    Task<BannerDto> GetBannerByIdAsync(string id);
    Task<BannerDto> CreateBannerAsync(CreateBannerDto dto);
    Task<BannerDto> UpdateBannerAsync(string id, UpdateBannerDto dto);
    Task<bool> DeleteBannerAsync(string id);
    Task<BannerDto> ToggleBannerStatusAsync(string id);
}
