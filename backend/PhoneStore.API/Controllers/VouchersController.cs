using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Voucher;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Enums;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class VouchersController : ControllerBase
{
    private readonly IVoucherService _voucherService;

    public VouchersController(IVoucherService voucherService)
    {
        _voucherService = voucherService;
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<VoucherDto>>>> GetAllVouchers()
    {
        var result = await _voucherService.GetAllVouchersAsync();
        return Ok(ApiResponse<List<VoucherDto>>.SuccessResponse(result));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<VoucherDto>>> GetVoucherById(string id)
    {
        var result = await _voucherService.GetVoucherByIdAsync(id);
        return Ok(ApiResponse<VoucherDto>.SuccessResponse(result));
    }

    [Authorize]
    [HttpGet("code/{code}")]
    public async Task<ActionResult<ApiResponse<VoucherDto>>> GetVoucherByCode(string code)
    {
        var result = await _voucherService.GetVoucherByCodeAsync(code);
        if (result == null)
            return NotFound(ApiResponse.ErrorResponse("Voucher not found"));
            
        return Ok(ApiResponse<VoucherDto>.SuccessResponse(result));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<VoucherDto>>> CreateVoucher([FromBody] CreateVoucherDto dto)
    {
        var result = await _voucherService.CreateVoucherAsync(dto);
        return CreatedAtAction(nameof(GetVoucherById), new { id = result.Id }, ApiResponse<VoucherDto>.SuccessResponse(result, "Voucher created successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<VoucherDto>>> UpdateVoucher(string id, [FromBody] UpdateVoucherDto dto)
    {
        var result = await _voucherService.UpdateVoucherAsync(id, dto);
        return Ok(ApiResponse<VoucherDto>.SuccessResponse(result, "Voucher updated successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse>> DeleteVoucher(string id)
    {
        await _voucherService.DeleteVoucherAsync(id);
        return Ok(ApiResponse.SuccessResponse("Voucher deleted successfully"));
    }
}
