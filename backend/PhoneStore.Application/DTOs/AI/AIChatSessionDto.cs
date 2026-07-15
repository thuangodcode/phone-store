using System;

namespace PhoneStore.Application.DTOs.AI;

public class AIChatSessionDto
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string UserRole { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? DeletedAt { get; set; }
    public bool IsDeleted => DeletedAt.HasValue;
}
