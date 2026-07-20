namespace PhoneStore.Application.DTOs.Review;

public class ReviewReplyDto
{
    public string Id { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string UserAvatar { get; set; } = string.Empty;
    public string UserRole { get; set; } = "Customer";
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

