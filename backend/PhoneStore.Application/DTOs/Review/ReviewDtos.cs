namespace PhoneStore.Application.DTOs.Review;

public class ReviewDto
{
    public string Id { get; set; } = null!;
    public string UserId { get; set; } = null!;
    public string UserName { get; set; } = string.Empty;
    public string UserAvatar { get; set; } = string.Empty;
    public string UserRole { get; set; } = "Customer";
    public string ProductId { get; set; } = null!;
    public string OrderId { get; set; } = null!;
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public List<ReviewReplyDto> Replies { get; set; } = new();
}

public class CreateReviewDto
{
    public string ProductId { get; set; } = null!;
    public string OrderId { get; set; } = null!;
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
}

public class UpdateReviewDto
{
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
}
