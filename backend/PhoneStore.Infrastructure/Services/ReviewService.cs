using AutoMapper;
using PhoneStore.Application.DTOs.Review;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Enums;
using PhoneStore.Domain.Interfaces;

namespace PhoneStore.Infrastructure.Services;

public class ReviewService : IReviewService
{
    private readonly IRepository<Review> _reviewRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<Order> _orderRepository;
    private readonly IRepository<User> _userRepository;
    private readonly IMapper _mapper;

    public ReviewService(
        IRepository<Review> reviewRepository,
        IRepository<Product> productRepository,
        IRepository<Order> orderRepository,
        IRepository<User> userRepository,
        IMapper mapper)
    {
        _reviewRepository = reviewRepository;
        _productRepository = productRepository;
        _orderRepository = orderRepository;
        _userRepository = userRepository;
        _mapper = mapper;
    }

    public async Task<List<ReviewDto>> GetProductReviewsAsync(string productId)
    {
        var reviews = await _reviewRepository.FindAsync(r => r.ProductId == productId);
        return _mapper.Map<List<ReviewDto>>(reviews.OrderByDescending(r => r.CreatedAt).ToList());
    }

    public async Task<ReviewDto> CreateReviewAsync(string userId, CreateReviewDto dto)
    {
        // Verify the order exists and belongs to the user
        var order = await _orderRepository.GetByIdAsync(dto.OrderId);
        if (order == null)
            throw new Exception("Order not found.");

        if (order.UserId != userId)
            throw new Exception("Access denied.");

        if (order.Status != OrderStatus.Delivered)
            throw new Exception("Can only review delivered orders.");

        // Check if user already reviewed this product for this order
        var existingReview = await _reviewRepository.FindOneAsync(
            r => r.UserId == userId && r.ProductId == dto.ProductId && r.OrderId == dto.OrderId);
        if (existingReview != null)
            throw new Exception("You already reviewed this product for this order.");

        // Validate rating
        if (dto.Rating < 1 || dto.Rating > 5)
            throw new Exception("Rating must be between 1 and 5.");

        var user = await _userRepository.GetByIdAsync(userId);

        var review = _mapper.Map<Review>(dto);
        review.UserId = userId;
        review.UserName = user?.FullName ?? "Anonymous";
        review.CreatedAt = DateTime.UtcNow;
        review.UpdatedAt = DateTime.UtcNow;

        await _reviewRepository.CreateAsync(review);

        // Update product average rating
        await UpdateProductRating(dto.ProductId);

        return _mapper.Map<ReviewDto>(review);
    }

    public async Task<ReviewDto> UpdateReviewAsync(string id, string userId, UpdateReviewDto dto)
    {
        var review = await _reviewRepository.GetByIdAsync(id);
        if (review == null)
            throw new Exception("Review not found.");

        if (review.UserId != userId)
            throw new Exception("Access denied.");

        if (dto.Rating < 1 || dto.Rating > 5)
            throw new Exception("Rating must be between 1 and 5.");

        review.Rating = dto.Rating;
        review.Comment = dto.Comment;
        review.UpdatedAt = DateTime.UtcNow;

        await _reviewRepository.UpdateAsync(id, review);
        await UpdateProductRating(review.ProductId);

        return _mapper.Map<ReviewDto>(review);
    }

    public async Task DeleteReviewAsync(string id, string userId)
    {
        var review = await _reviewRepository.GetByIdAsync(id);
        if (review == null)
            throw new Exception("Review not found.");

        if (review.UserId != userId)
            throw new Exception("Access denied.");

        var productId = review.ProductId;
        await _reviewRepository.DeleteAsync(id);
        await UpdateProductRating(productId);
    }

    private async Task UpdateProductRating(string productId)
    {
        var reviews = (await _reviewRepository.FindAsync(r => r.ProductId == productId)).ToList();
        var product = await _productRepository.GetByIdAsync(productId);
        if (product == null) return;

        if (reviews.Any())
        {
            product.AverageRating = reviews.Average(r => r.Rating);
            product.TotalReviews = reviews.Count;
        }
        else
        {
            product.AverageRating = 0;
            product.TotalReviews = 0;
        }

        product.UpdatedAt = DateTime.UtcNow;
        await _productRepository.UpdateAsync(productId, product);
    }
}
