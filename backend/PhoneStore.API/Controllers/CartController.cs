using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Cart;
using PhoneStore.Application.Interfaces;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class CartController : ControllerBase
{
    private readonly ICartService _cartService;

    public CartController(ICartService cartService)
    {
        _cartService = cartService;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    [HttpGet]
    public async Task<ActionResult<ApiResponse<CartDto>>> GetCart()
    {
        var result = await _cartService.GetCartAsync(GetUserId());
        return Ok(ApiResponse<CartDto>.SuccessResponse(result));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<CartDto>>> AddToCart([FromBody] AddToCartDto dto)
    {
        var result = await _cartService.AddToCartAsync(GetUserId(), dto);
        return Ok(ApiResponse<CartDto>.SuccessResponse(result, "Item added to cart"));
    }

    [HttpPut("{productId}")]
    public async Task<ActionResult<ApiResponse<CartDto>>> UpdateCartItem(string productId, [FromBody] UpdateCartItemDto dto)
    {
        var result = await _cartService.UpdateCartItemAsync(GetUserId(), productId, dto);
        return Ok(ApiResponse<CartDto>.SuccessResponse(result, "Cart item updated"));
    }

    [HttpDelete("{productId}")]
    public async Task<ActionResult<ApiResponse<CartDto>>> RemoveFromCart(string productId)
    {
        var result = await _cartService.RemoveFromCartAsync(GetUserId(), productId);
        return Ok(ApiResponse<CartDto>.SuccessResponse(result, "Item removed from cart"));
    }

    [HttpDelete]
    public async Task<ActionResult<ApiResponse>> ClearCart()
    {
        await _cartService.ClearCartAsync(GetUserId());
        return Ok(ApiResponse.SuccessResponse("Cart cleared successfully"));
    }
}
