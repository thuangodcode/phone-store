using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Brand;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Enums;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class BrandsController : ControllerBase
{
    private readonly IBrandService _brandService;

    public BrandsController(IBrandService brandService)
    {
        _brandService = brandService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<BrandDto>>>> GetAllBrands()
    {
        var result = await _brandService.GetAllBrandsAsync();
        return Ok(ApiResponse<List<BrandDto>>.SuccessResponse(result));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<BrandDto>>> GetBrandById(string id)
    {
        var result = await _brandService.GetBrandByIdAsync(id);
        return Ok(ApiResponse<BrandDto>.SuccessResponse(result));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<BrandDto>>> CreateBrand([FromBody] CreateBrandDto dto)
    {
        var result = await _brandService.CreateBrandAsync(dto);
        return CreatedAtAction(nameof(GetBrandById), new { id = result.Id }, ApiResponse<BrandDto>.SuccessResponse(result, "Brand created successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<BrandDto>>> UpdateBrand(string id, [FromBody] UpdateBrandDto dto)
    {
        var result = await _brandService.UpdateBrandAsync(id, dto);
        return Ok(ApiResponse<BrandDto>.SuccessResponse(result, "Brand updated successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse>> DeleteBrand(string id)
    {
        await _brandService.DeleteBrandAsync(id);
        return Ok(ApiResponse.SuccessResponse("Brand deleted successfully"));
    }
}
