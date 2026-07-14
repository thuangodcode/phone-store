using PhoneStore.Application.DTOs.Wishlist;

namespace PhoneStore.Application.Interfaces;

public interface IWishlistService
{
    Task<WishlistDto> GetWishlistAsync(string userId);
    Task<WishlistDto> AddToWishlistAsync(string userId, string productId);
    Task<WishlistDto> RemoveFromWishlistAsync(string userId, string productId);
}
