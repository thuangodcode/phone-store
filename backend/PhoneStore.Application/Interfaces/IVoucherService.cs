using PhoneStore.Application.DTOs.Voucher;

namespace PhoneStore.Application.Interfaces;

public interface IVoucherService
{
    Task<List<VoucherDto>> GetAllVouchersAsync();
    Task<VoucherDto> GetVoucherByIdAsync(string id);
    Task<VoucherDto?> GetVoucherByCodeAsync(string code);
    Task<VoucherDto> CreateVoucherAsync(CreateVoucherDto dto);
    Task<VoucherDto> UpdateVoucherAsync(string id, UpdateVoucherDto dto);
    Task DeleteVoucherAsync(string id);
    Task<decimal> CalculateDiscountAsync(string voucherCode, decimal orderAmount);
}
