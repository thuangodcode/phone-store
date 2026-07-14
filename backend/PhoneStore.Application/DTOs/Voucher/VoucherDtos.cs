namespace PhoneStore.Application.DTOs.Voucher;

public class VoucherDto
{
    public string Id { get; set; } = null!;
    public string Code { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
    public string DiscountType { get; set; } = null!;
    public decimal DiscountValue { get; set; }
    public decimal MinOrderAmount { get; set; }
    public decimal MaxDiscount { get; set; }
    public int Quantity { get; set; }
    public int Used { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateVoucherDto
{
    public string Code { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
    public string DiscountType { get; set; } = "Percentage";
    public decimal DiscountValue { get; set; }
    public decimal MinOrderAmount { get; set; }
    public decimal MaxDiscount { get; set; }
    public int Quantity { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
}

public class UpdateVoucherDto
{
    public string Description { get; set; } = string.Empty;
    public string DiscountType { get; set; } = "Percentage";
    public decimal DiscountValue { get; set; }
    public decimal MinOrderAmount { get; set; }
    public decimal MaxDiscount { get; set; }
    public int Quantity { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
}
