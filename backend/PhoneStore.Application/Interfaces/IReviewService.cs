using PhoneStore.Application.DTOs.Review;

namespace PhoneStore.Application.Interfaces;

public interface IReviewService
{
    Task<List<ReviewDto>> GetProductReviewsAsync(string productId);
    Task<ReviewDto> CreateReviewAsync(string userId, CreateReviewDto dto);
    Task<ReviewDto> UpdateReviewAsync(string id, string userId, UpdateReviewDto dto);
    Task DeleteReviewAsync(string id, string userId);
}
