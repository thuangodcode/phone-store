using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Review;

namespace PhoneStore.Application.Interfaces;

public interface IReviewService
{
    Task<IEnumerable<ReviewDto>> GetByProductIdAsync(string productId);
    Task<ReviewDto> CreateAsync(string userId, string userName, CreateReviewDto dto);
    Task<bool> UpdateAsync(string id, string userId, UpdateReviewDto dto);
    Task<bool> DeleteAsync(string id, string userId);
    Task<bool> DeleteAsAdminAsync(string id);
    Task<ReviewDto> AddReplyAsync(string reviewId, string userId, string userName, string comment);
}

