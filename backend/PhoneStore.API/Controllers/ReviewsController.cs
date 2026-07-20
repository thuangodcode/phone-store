using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Review;
using PhoneStore.Application.Interfaces;
using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using PhoneStore.API.Hubs;
using MongoDB.Driver;

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

    [HttpDelete("admin/{id}")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteReviewAsAdmin(string id)
    {
        var result = await _reviewService.DeleteAsAdminAsync(id);
        return Ok(ApiResponse<bool>.SuccessResponse(result));
    }

    [HttpPut("{reviewId}/reply/{replyId}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<bool>>> UpdateReply(string reviewId, string replyId, [FromBody] string comment)
    {
        var review = await _reviewService.UpdateReplyAsync(reviewId, replyId, GetUserId(), comment);
        if (review != null)
        {
            await _hubContext.Clients.Group(review.ProductId).SendAsync("ReceiveReview", review);
            return Ok(ApiResponse<bool>.SuccessResponse(true, "Reply updated"));
        }
        return BadRequest(ApiResponse<bool>.ErrorResponse("Update failed or unauthorized"));
    }

    [HttpDelete("{reviewId}/reply/{replyId}")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<bool>>> DeleteReply(string reviewId, string replyId)
    {
        var review = await _reviewService.DeleteReplyAsync(reviewId, replyId, GetUserId());
        if (review != null)
        {
            await _hubContext.Clients.Group(review.ProductId).SendAsync("ReceiveReview", review);
            return Ok(ApiResponse<bool>.SuccessResponse(true, "Reply deleted"));
        }
        return BadRequest(ApiResponse<bool>.ErrorResponse("Delete failed or unauthorized"));
    }

    [HttpGet("fix-db")]
    public async Task<ActionResult> FixDb([FromServices] PhoneStore.Infrastructure.Data.MongoDbContext context)
    {
        var collection = context.Database.GetCollection<MongoDB.Bson.BsonDocument>("reviews");
        var docs = await collection.Find(new MongoDB.Bson.BsonDocument()).ToListAsync();
        int fixedCount = 0;
        foreach (var doc in docs)
        {
            bool modified = false;
            if (doc.Contains("replies") && doc["replies"].IsBsonArray)
            {
                var replies = doc["replies"].AsBsonArray;
                foreach (var reply in replies)
                {
                    if (reply.IsBsonDocument)
                    {
                        var replyDoc = reply.AsBsonDocument;
                        if (replyDoc.Contains("Comment") && !replyDoc["Comment"].IsString)
                        {
                            replyDoc["Comment"] = replyDoc["Comment"].ToJson();
                            modified = true;
                        }
                        if (replyDoc.Contains("comment"))
                        {
                            if (replyDoc["comment"].IsString && (!replyDoc.Contains("Comment") || !replyDoc["Comment"].IsString))
                            {
                                replyDoc["Comment"] = replyDoc["comment"];
                            }
                            replyDoc.Remove("comment");
                            modified = true;
                        }
                    }
                }
            }
            if (modified)
            {
                var filter = MongoDB.Driver.Builders<MongoDB.Bson.BsonDocument>.Filter.Eq("_id", doc["_id"]);
                await collection.ReplaceOneAsync(filter, doc);
                fixedCount++;
            }
        }
        return Ok(new { message = "Database fixed", fixedCount });
    }
}
