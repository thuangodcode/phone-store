using AutoMapper;
using MongoDB.Driver;
using PhoneStore.Application.DTOs.Review;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class ReviewService : IReviewService
{
    private readonly MongoDbContext _context;
    private readonly IMapper _mapper;

    public ReviewService(MongoDbContext context, IMapper mapper)
    {
        _context = context;
        _mapper = mapper;
    }

    public async Task<IEnumerable<ReviewDto>> GetByProductIdAsync(string productId)
    {
        var reviews = await _context.Reviews.Find(r => r.ProductId == productId).SortByDescending(r => r.CreatedAt).ToListAsync();
        return _mapper.Map<IEnumerable<ReviewDto>>(reviews);
    }

    public async Task<ReviewDto> CreateAsync(string userId, string userName, CreateReviewDto dto)
    {
        var user = await _context.Users.Find(u => u.Id == userId).FirstOrDefaultAsync();
        var review = _mapper.Map<Review>(dto);
        review.UserId = userId;
        review.UserName = userName;
        review.UserAvatar = user?.Avatar ?? string.Empty;
        review.UserRole = user?.Role ?? "Customer";
        review.CreatedAt = DateTime.UtcNow;
        review.UpdatedAt = DateTime.UtcNow;

        await _context.Reviews.InsertOneAsync(review);
        return _mapper.Map<ReviewDto>(review);
    }

    public async Task<bool> UpdateAsync(string id, string userId, UpdateReviewDto dto)
    {
        var update = Builders<Review>.Update
            .Set(r => r.Rating, dto.Rating)
            .Set(r => r.Comment, dto.Comment)
            .Set(r => r.UpdatedAt, DateTime.UtcNow);

        var result = await _context.Reviews.UpdateOneAsync(r => r.Id == id && r.UserId == userId, update);
        return result.ModifiedCount > 0;
    }

    public async Task<bool> DeleteAsync(string id, string userId)
    {
        var result = await _context.Reviews.DeleteOneAsync(r => r.Id == id && r.UserId == userId);
        return result.DeletedCount > 0;
    }

    public async Task<bool> DeleteAsAdminAsync(string id)
    {
        var result = await _context.Reviews.DeleteOneAsync(r => r.Id == id);
        return result.DeletedCount > 0;
    }

    public async Task<ReviewDto> AddReplyAsync(string reviewId, string userId, string userName, string comment)
    {
        var user = await _context.Users.Find(u => u.Id == userId).FirstOrDefaultAsync();
        var reply = new ReviewReply
        {
            UserId = userId,
            UserName = userName,
            UserAvatar = user?.Avatar ?? string.Empty,
            UserRole = user?.Role ?? "Customer",
            Comment = comment,
            CreatedAt = DateTime.UtcNow
        };

        var update = Builders<Review>.Update.Push(r => r.Replies, reply);
        await _context.Reviews.UpdateOneAsync(r => r.Id == reviewId, update);
        
        var updatedReview = await _context.Reviews.Find(r => r.Id == reviewId).FirstOrDefaultAsync();
        return _mapper.Map<ReviewDto>(updatedReview);
    }
}

