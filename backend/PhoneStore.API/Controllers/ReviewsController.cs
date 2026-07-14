using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Review;
using PhoneStore.Application.Interfaces;
using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using PhoneStore.API.Hubs;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ReviewsController : ControllerBase
{
    private readonly IReviewService _reviewService;
    private readonly IHubContext<ReviewHub> _hubContext;

    public ReviewsController(IReviewService reviewService, IHubContext<ReviewHub> hubContext)
    {
        _reviewService = reviewService;
        _hubContext = hubContext;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    private string GetUserName() => User.FindFirstValue(ClaimTypes.Name) ?? "User";

    [HttpGet("product/{productId}")]
    public async Task<ActionResult<ApiResponse<IEnumerable<ReviewDto>>>> GetByProduct(string productId)
    {
        var result = await _reviewService.GetByProductIdAsync(productId);
        return Ok(ApiResponse<IEnumerable<ReviewDto>>.SuccessResponse(result));
    }

    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> CreateReview(CreateReviewDto dto)
    {
        var result = await _reviewService.CreateAsync(GetUserId(), GetUserName(), dto);
        await _hubContext.Clients.Group(dto.ProductId).SendAsync("ReceiveReview", result);
        return Ok(ApiResponse<ReviewDto>.SuccessResponse(result, "Review submitted"));
    }

    [HttpPost("{id}/reply")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> AddReply(string id, [FromBody] string comment)
    {
        var review = await _reviewService.AddReplyAsync(id, GetUserId(), GetUserName(), comment);
        await _hubContext.Clients.Group(review.ProductId).SendAsync("ReceiveReview", review);
        return Ok(ApiResponse<ReviewDto>.SuccessResponse(review, "Reply added"));
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateReview(string id, UpdateReviewDto dto)
    {
        var result = await _reviewService.UpdateAsync(id, GetUserId(), dto);
        return Ok(ApiResponse<bool>.SuccessResponse(result));
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteReview(string id)
    {
        var result = await _reviewService.DeleteAsync(id, GetUserId());
        return Ok(ApiResponse<bool>.SuccessResponse(result));
    }
}

