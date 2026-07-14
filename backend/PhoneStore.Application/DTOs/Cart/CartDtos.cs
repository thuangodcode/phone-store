namespace PhoneStore.Application.DTOs.Cart;

public class CartDto
{
    public string Id { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public List<CartItemDto> Items { get; set; } = new();
    public decimal TotalAmount { get; set; }
}

public class CartItemDto
{
    public string ProductId { get; set; } = null!;
    public string ProductName { get; set; } = string.Empty;
    public string ProductImage { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal SalePrice { get; set; }
    public int Quantity { get; set; }
    public int Stock { get; set; }
    public string Storage { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
}

public class AddToCartDto
{
    public string ProductId { get; set; } = null!;
    public int Quantity { get; set; } = 1;
    public string Storage { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
}

public class UpdateCartItemDto
{
    public int Quantity { get; set; }
    public string Storage { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
}
