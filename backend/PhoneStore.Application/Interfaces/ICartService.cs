using PhoneStore.Application.DTOs.Cart;

namespace PhoneStore.Application.Interfaces;

public interface ICartService
{
    Task<CartDto> GetCartAsync(string userId);
    Task<CartDto> AddToCartAsync(string userId, AddToCartDto dto);
    Task<CartDto> UpdateCartItemAsync(string userId, string productId, UpdateCartItemDto dto);
    Task<CartDto> RemoveFromCartAsync(string userId, string productId);
    Task ClearCartAsync(string userId);
}
