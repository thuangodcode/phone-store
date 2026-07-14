using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Review;
using PhoneStore.Application.Interfaces;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;

    public ReviewsController(IReviewService reviewService)
    {
        _reviewService = reviewService;
    }

    [HttpGet("product/{productId}")]
    public async Task<ActionResult<ApiResponse<List<ReviewDto>>>> GetProductReviews(string productId)
    {
        var result = await _reviewService.GetProductReviewsAsync(productId);
        return Ok(ApiResponse<List<ReviewDto>>.SuccessResponse(result));
    }

    [Authorize]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> CreateReview([FromBody] CreateReviewDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var result = await _reviewService.CreateReviewAsync(userId, dto);
        return Ok(ApiResponse<ReviewDto>.SuccessResponse(result, "Review submitted successfully"));
    }

    [Authorize]
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> UpdateReview(string id, [FromBody] UpdateReviewDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var result = await _reviewService.UpdateReviewAsync(id, userId, dto);
        return Ok(ApiResponse<ReviewDto>.SuccessResponse(result, "Review updated successfully"));
    }

    [Authorize]
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse>> DeleteReview(string id)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        await _reviewService.DeleteReviewAsync(id, userId);
        return Ok(ApiResponse.SuccessResponse("Review deleted successfully"));
    }
}
