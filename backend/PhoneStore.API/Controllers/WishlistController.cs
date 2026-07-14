using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Wishlist;
using PhoneStore.Application.Interfaces;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class WishlistController : ControllerBase
{
    private readonly IWishlistService _wishlistService;

    public WishlistController(IWishlistService wishlistService)
    {
        _wishlistService = wishlistService;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    [HttpGet]
    public async Task<ActionResult<ApiResponse<WishlistDto>>> GetWishlist()
    {
        var result = await _wishlistService.GetWishlistAsync(GetUserId());
        return Ok(ApiResponse<WishlistDto>.SuccessResponse(result));
    }

    [HttpPost("{productId}")]
    public async Task<ActionResult<ApiResponse<WishlistDto>>> AddToWishlist(string productId)
    {
        var result = await _wishlistService.AddToWishlistAsync(GetUserId(), productId);
        return Ok(ApiResponse<WishlistDto>.SuccessResponse(result, "Added to wishlist"));
    }

    [HttpDelete("{productId}")]
    public async Task<ActionResult<ApiResponse<WishlistDto>>> RemoveFromWishlist(string productId)
    {
        var result = await _wishlistService.RemoveFromWishlistAsync(GetUserId(), productId);
        return Ok(ApiResponse<WishlistDto>.SuccessResponse(result, "Removed from wishlist"));
    }
}
