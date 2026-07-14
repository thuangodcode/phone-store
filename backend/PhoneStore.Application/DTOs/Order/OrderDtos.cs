namespace PhoneStore.Application.DTOs.Order;

public class OrderDto
{
    public string Id { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public string UserName { get; set; } = string.Empty;
    public List<OrderItemDto> Items { get; set; } = new();
    public decimal TotalAmount { get; set; }
    public decimal DiscountAmount { get; set; }
    public decimal FinalAmount { get; set; }
    public string? VoucherCode { get; set; }
    public string ShippingAddress { get; set; } = null!;
    public string Phone { get; set; } = null!;
    public string ReceiverName { get; set; } = null!;
    public string Status { get; set; } = null!;
    public string PaymentMethod { get; set; } = null!;
    public string Note { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class OrderItemDto
{
    public string ProductId { get; set; } = null!;
    public string ProductName { get; set; } = null!;
    public string ProductImage { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal Price { get; set; }
}

public class CreateOrderDto
{
    public string ShippingAddress { get; set; } = null!;
    public string Phone { get; set; } = null!;
    public string ReceiverName { get; set; } = null!;
    public string? VoucherCode { get; set; }
    public string PaymentMethod { get; set; } = "COD";
    public string Note { get; set; } = string.Empty;
}

public class UpdateOrderStatusDto
{
    public string Status { get; set; } = null!;
}
