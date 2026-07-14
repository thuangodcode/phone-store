using AutoMapper;
using PhoneStore.Application.DTOs.Voucher;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Enums;
using PhoneStore.Domain.Interfaces;

namespace PhoneStore.Infrastructure.Services;

public class VoucherService : IVoucherService
{
    private readonly IRepository<Voucher> _voucherRepository;
    private readonly IMapper _mapper;

    public VoucherService(IRepository<Voucher> voucherRepository, IMapper mapper)
    {
        _voucherRepository = voucherRepository;
        _mapper = mapper;
    }

    public async Task<List<VoucherDto>> GetAllVouchersAsync()
    {
        var vouchers = await _voucherRepository.GetAllAsync();
        return _mapper.Map<List<VoucherDto>>(vouchers);
    }

    public async Task<VoucherDto> GetVoucherByIdAsync(string id)
    {
        var voucher = await _voucherRepository.GetByIdAsync(id);
        if (voucher == null)
            throw new Exception("Voucher not found.");
        return _mapper.Map<VoucherDto>(voucher);
    }

    public async Task<VoucherDto?> GetVoucherByCodeAsync(string code)
    {
        var voucher = await _voucherRepository.FindOneAsync(v => v.Code == code.ToUpper());
        if (voucher == null) return null;
        return _mapper.Map<VoucherDto>(voucher);
    }

    public async Task<VoucherDto> CreateVoucherAsync(CreateVoucherDto dto)
    {
        // Check if code already exists
        var existing = await _voucherRepository.FindOneAsync(v => v.Code == dto.Code.ToUpper());
        if (existing != null)
            throw new Exception("Voucher code already exists.");

        var voucher = _mapper.Map<Voucher>(dto);
        voucher.Code = dto.Code.ToUpper();
        voucher.CreatedAt = DateTime.UtcNow;

        await _voucherRepository.CreateAsync(voucher);
        return _mapper.Map<VoucherDto>(voucher);
    }

    public async Task<VoucherDto> UpdateVoucherAsync(string id, UpdateVoucherDto dto)
    {
        var voucher = await _voucherRepository.GetByIdAsync(id);
        if (voucher == null)
            throw new Exception("Voucher not found.");

        voucher.Description = dto.Description;
        voucher.DiscountType = dto.DiscountType;
        voucher.DiscountValue = dto.DiscountValue;
        voucher.MinOrderAmount = dto.MinOrderAmount;
        voucher.MaxDiscount = dto.MaxDiscount;
        voucher.Quantity = dto.Quantity;
        voucher.StartDate = dto.StartDate;
        voucher.EndDate = dto.EndDate;
        voucher.IsActive = dto.IsActive;

        await _voucherRepository.UpdateAsync(id, voucher);
        return _mapper.Map<VoucherDto>(voucher);
    }

    public async Task DeleteVoucherAsync(string id)
    {
        var voucher = await _voucherRepository.GetByIdAsync(id);
        if (voucher == null)
            throw new Exception("Voucher not found.");
        await _voucherRepository.DeleteAsync(id);
    }

    public async Task<decimal> CalculateDiscountAsync(string voucherCode, decimal orderAmount)
    {
        var voucher = await _voucherRepository.FindOneAsync(v => v.Code == voucherCode.ToUpper());
        if (voucher == null)
            throw new Exception("Voucher not found.");

        if (!voucher.IsActive)
            throw new Exception("Voucher is not active.");

        if (DateTime.UtcNow < voucher.StartDate || DateTime.UtcNow > voucher.EndDate)
            throw new Exception("Voucher has expired or is not yet valid.");

        if (voucher.Used >= voucher.Quantity)
            throw new Exception("Voucher has been fully used.");

        if (orderAmount < voucher.MinOrderAmount)
            throw new Exception($"Minimum order amount is {voucher.MinOrderAmount}.");

        decimal discount;
        if (voucher.DiscountType == DiscountType.Percentage)
        {
            discount = orderAmount * voucher.DiscountValue / 100;
            if (voucher.MaxDiscount > 0 && discount > voucher.MaxDiscount)
                discount = voucher.MaxDiscount;
        }
        else
        {
            discount = voucher.DiscountValue;
        }

        // Increment used count
        voucher.Used++;
        await _voucherRepository.UpdateAsync(voucher.Id, voucher);

        return discount;
    }
}
