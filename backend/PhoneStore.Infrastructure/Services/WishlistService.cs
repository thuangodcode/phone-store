using AutoMapper;
using PhoneStore.Application.DTOs.Wishlist;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Interfaces;

namespace PhoneStore.Infrastructure.Services;

public class WishlistService : IWishlistService
{
    private readonly IRepository<Wishlist> _wishlistRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IMapper _mapper;

    public WishlistService(
        IRepository<Wishlist> wishlistRepository,
        IRepository<Product> productRepository,
        IMapper mapper)
    {
        _wishlistRepository = wishlistRepository;
        _productRepository = productRepository;
        _mapper = mapper;
    }

    public async Task<WishlistDto> GetWishlistAsync(string userId)
    {
        var wishlist = await _wishlistRepository.FindOneAsync(w => w.UserId == userId);
        if (wishlist == null)
        {
            wishlist = new Wishlist { UserId = userId, ProductIds = new List<string>() };
            await _wishlistRepository.CreateAsync(wishlist);
        }

        return await MapWishlistToDto(wishlist);
    }

    public async Task<WishlistDto> AddToWishlistAsync(string userId, string productId)
    {
        var product = await _productRepository.GetByIdAsync(productId);
        if (product == null)
            throw new Exception("Product not found.");

        var wishlist = await _wishlistRepository.FindOneAsync(w => w.UserId == userId);
        if (wishlist == null)
        {
            wishlist = new Wishlist { UserId = userId, ProductIds = new List<string>() };
            await _wishlistRepository.CreateAsync(wishlist);
        }

        if (!wishlist.ProductIds.Contains(productId))
        {
            wishlist.ProductIds.Add(productId);
            wishlist.UpdatedAt = DateTime.UtcNow;
            await _wishlistRepository.UpdateAsync(wishlist.Id, wishlist);
        }

        return await MapWishlistToDto(wishlist);
    }

    public async Task<WishlistDto> RemoveFromWishlistAsync(string userId, string productId)
    {
        var wishlist = await _wishlistRepository.FindOneAsync(w => w.UserId == userId);
        if (wishlist == null)
            throw new Exception("Wishlist not found.");

        wishlist.ProductIds.Remove(productId);
        wishlist.UpdatedAt = DateTime.UtcNow;
        await _wishlistRepository.UpdateAsync(wishlist.Id, wishlist);

        return await MapWishlistToDto(wishlist);
    }

    private async Task<WishlistDto> MapWishlistToDto(Wishlist wishlist)
    {
        var dto = new WishlistDto
        {
            Id = wishlist.Id,
            UserId = wishlist.UserId,
            Items = new List<WishlistItemDto>()
        };

        foreach (var productId in wishlist.ProductIds)
        {
            var product = await _productRepository.GetByIdAsync(productId);
            if (product == null) continue;

            dto.Items.Add(new WishlistItemDto
            {
                ProductId = product.Id,
                ProductName = product.Name,
                ProductImage = product.Images.FirstOrDefault() ?? string.Empty,
                Price = product.Price,
                SalePrice = product.SalePrice > 0 ? product.SalePrice : product.Price,
                InStock = product.Stock > 0
            });
        }

        return dto;
    }
}
