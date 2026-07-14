namespace PhoneStore.Application.DTOs.Wishlist;

public class WishlistDto
{
    public string Id { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public List<WishlistItemDto> Items { get; set; } = new();
}

public class WishlistItemDto
{
    public string ProductId { get; set; } = null!;
    public string ProductName { get; set; } = string.Empty;
    public string ProductImage { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal SalePrice { get; set; }
    public bool InStock { get; set; }
}
