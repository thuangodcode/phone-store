using AutoMapper;
using PhoneStore.Application.DTOs.Cart;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Interfaces;

namespace PhoneStore.Infrastructure.Services;

public class CartService : ICartService
{
    private readonly IRepository<Cart> _cartRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IMapper _mapper;

    public CartService(IRepository<Cart> cartRepository, IRepository<Product> productRepository, IMapper mapper)
    {
        _cartRepository = cartRepository;
        _productRepository = productRepository;
        _mapper = mapper;
    }

    public async Task<CartDto> GetCartAsync(string userId)
    {
        var cart = await _cartRepository.FindOneAsync(c => c.UserId == userId);
        if (cart == null)
        {
            cart = new Cart { UserId = userId, Items = new List<CartItem>() };
            await _cartRepository.CreateAsync(cart);
        }

        return await MapCartToDto(cart);
    }

    public async Task<CartDto> AddToCartAsync(string userId, AddToCartDto dto)
    {
        var product = await _productRepository.GetByIdAsync(dto.ProductId);
        if (product == null)
            throw new Exception("Product not found.");

        if (product.Stock < dto.Quantity)
            throw new Exception("Not enough stock.");

        var cart = await _cartRepository.FindOneAsync(c => c.UserId == userId);
        if (cart == null)
        {
            cart = new Cart { UserId = userId, Items = new List<CartItem>() };
            await _cartRepository.CreateAsync(cart);
        }

        var existingItem = cart.Items.FirstOrDefault(i => i.ProductId == dto.ProductId && i.Storage == dto.Storage && i.Color == dto.Color);
        if (existingItem != null)
        {
            existingItem.Quantity += dto.Quantity;
            if (existingItem.Quantity > product.Stock)
                throw new Exception("Not enough stock.");
        }
        else
        {
            cart.Items.Add(new CartItem
            {
                ProductId = dto.ProductId,
                Quantity = dto.Quantity,
                Storage = dto.Storage,
                Color = dto.Color
            });
        }

        cart.UpdatedAt = DateTime.UtcNow;
        await _cartRepository.UpdateAsync(cart.Id, cart);

        return await MapCartToDto(cart);
    }

    public async Task<CartDto> UpdateCartItemAsync(string userId, string productId, UpdateCartItemDto dto)
    {
        var cart = await _cartRepository.FindOneAsync(c => c.UserId == userId);
        if (cart == null)
            throw new Exception("Cart not found.");

        var item = cart.Items.FirstOrDefault(i => i.ProductId == productId && i.Storage == dto.Storage && i.Color == dto.Color);
        if (item == null)
            throw new Exception("Item not found in cart.");

        if (dto.Quantity <= 0)
        {
            cart.Items.Remove(item);
        }
        else
        {
            var product = await _productRepository.GetByIdAsync(productId);
            if (product != null && dto.Quantity > product.Stock)
                throw new Exception("Not enough stock.");

            item.Quantity = dto.Quantity;
        }

        cart.UpdatedAt = DateTime.UtcNow;
        await _cartRepository.UpdateAsync(cart.Id, cart);

        return await MapCartToDto(cart);
    }

    public async Task<CartDto> RemoveFromCartAsync(string userId, string productId)
    {
        var cart = await _cartRepository.FindOneAsync(c => c.UserId == userId);
        if (cart == null)
            throw new Exception("Cart not found.");

        cart.Items.RemoveAll(i => i.ProductId == productId);
        cart.UpdatedAt = DateTime.UtcNow;
        await _cartRepository.UpdateAsync(cart.Id, cart);

        return await MapCartToDto(cart);
    }

    public async Task ClearCartAsync(string userId)
    {
        var cart = await _cartRepository.FindOneAsync(c => c.UserId == userId);
        if (cart == null) return;

        cart.Items.Clear();
        cart.UpdatedAt = DateTime.UtcNow;
        await _cartRepository.UpdateAsync(cart.Id, cart);
    }

    private async Task<CartDto> MapCartToDto(Cart cart)
    {
        var cartDto = new CartDto
        {
            Id = cart.Id,
            UserId = cart.UserId,
            Items = new List<CartItemDto>()
        };

        decimal totalAmount = 0;

        foreach (var item in cart.Items)
        {
            var product = await _productRepository.GetByIdAsync(item.ProductId);
            if (product == null) continue;

            var basePrice = product.Price;
            var salePrice = product.SalePrice > 0 ? product.SalePrice : product.Price;

            if (!string.IsNullOrEmpty(item.Storage))
            {
                var storageVariant = product.StorageVariants.FirstOrDefault(v => v.Storage == item.Storage);
                if (storageVariant != null)
                {
                    basePrice = storageVariant.Price;
                    salePrice = storageVariant.SalePrice > 0 ? storageVariant.SalePrice : storageVariant.Price;
                }
            }

            var image = product.Images.FirstOrDefault() ?? string.Empty;
            if (!string.IsNullOrEmpty(item.Color))
            {
                var colorVariant = product.ColorVariants.FirstOrDefault(v => v.Name == item.Color);
                if (colorVariant != null)
                {
                    salePrice += colorVariant.PriceModifier;
                    basePrice += colorVariant.PriceModifier;
                    if (!string.IsNullOrEmpty(colorVariant.ImageUrl))
                    {
                        image = colorVariant.ImageUrl;
                    }
                }
            }

            var cartItemDto = new CartItemDto
            {
                ProductId = item.ProductId,
                ProductName = product.Name,
                ProductImage = image,
                Price = basePrice,
                SalePrice = salePrice,
                Quantity = item.Quantity,
                Stock = product.Stock,
                Storage = item.Storage,
                Color = item.Color
            };

            totalAmount += cartItemDto.SalePrice * item.Quantity;
            cartDto.Items.Add(cartItemDto);
        }

        cartDto.TotalAmount = totalAmount;
        return cartDto;
    }
}
