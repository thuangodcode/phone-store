using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
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
    public async Task<ActionResult<List<BannerDto>>> GetAllBanners()
    {
        var banners = await _bannerService.GetAllBannersAsync();
        return Ok(banners);
    }

    [HttpGet("active")]
    public async Task<ActionResult<BannerDto>> GetActiveBanner()
    {
        var banner = await _bannerService.GetActiveBannerAsync();
        if (banner == null) return NotFound();
        return Ok(banner);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<BannerDto>> GetBannerById(string id)
    {
        var banner = await _bannerService.GetBannerByIdAsync(id);
        if (banner == null) return NotFound();
        return Ok(banner);
    }

    [HttpPost]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<BannerDto>> CreateBanner([FromBody] CreateBannerDto dto)
    {
        var banner = await _bannerService.CreateBannerAsync(dto);
        return CreatedAtAction(nameof(GetBannerById), new { id = banner.Id }, banner);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<BannerDto>> UpdateBanner(string id, [FromBody] UpdateBannerDto dto)
    {
        var banner = await _bannerService.UpdateBannerAsync(id, dto);
        return Ok(banner);
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult> DeleteBanner(string id)
    {
        await _bannerService.DeleteBannerAsync(id);
        return NoContent();
    }

    [HttpPatch("{id}/toggle")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<BannerDto>> ToggleBannerStatus(string id)
    {
        var banner = await _bannerService.ToggleBannerStatusAsync(id);
        return Ok(banner);
    }
}
