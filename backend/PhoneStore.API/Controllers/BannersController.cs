using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Banner;
using PhoneStore.Application.Interfaces;

namespace PhoneStore.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class BannersController : ControllerBase
{
    private readonly IBannerService _bannerService;

    public BannersController(IBannerService bannerService)
    {
        _bannerService = bannerService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<BannerDto>>>> GetAllBanners()
    {
        var banners = await _bannerService.GetAllBannersAsync();
        return Ok(ApiResponse<List<BannerDto>>.SuccessResponse(banners));
    }

    [HttpGet("active")]
    public async Task<ActionResult<ApiResponse<BannerDto>>> GetActiveBanner()
    {
        var banner = await _bannerService.GetActiveBannerAsync();
        if (banner == null) return NotFound(ApiResponse.ErrorResponse("Active banner not found"));
        return Ok(ApiResponse<BannerDto>.SuccessResponse(banner));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<BannerDto>>> GetBannerById(string id)
    {
        var banner = await _bannerService.GetBannerByIdAsync(id);
        if (banner == null) return NotFound(ApiResponse.ErrorResponse("Banner not found"));
        return Ok(ApiResponse<BannerDto>.SuccessResponse(banner));
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<BannerDto>>> CreateBanner([FromBody] CreateBannerDto dto)
    {
        var banner = await _bannerService.CreateBannerAsync(dto);
        return CreatedAtAction(nameof(GetBannerById), new { id = banner.Id }, ApiResponse<BannerDto>.SuccessResponse(banner, "Banner created successfully"));
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<BannerDto>>> UpdateBanner(string id, [FromBody] UpdateBannerDto dto)
    {
        var banner = await _bannerService.UpdateBannerAsync(id, dto);
        return Ok(ApiResponse<BannerDto>.SuccessResponse(banner, "Banner updated successfully"));
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse>> DeleteBanner(string id)
    {
        await _bannerService.DeleteBannerAsync(id);
        return Ok(ApiResponse.SuccessResponse("Banner deleted successfully"));
    }

    [HttpPatch("{id}/toggle")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<BannerDto>>> ToggleBannerStatus(string id)
    {
        var banner = await _bannerService.ToggleBannerStatusAsync(id);
        return Ok(ApiResponse<BannerDto>.SuccessResponse(banner, "Banner status updated successfully"));
    }
}
