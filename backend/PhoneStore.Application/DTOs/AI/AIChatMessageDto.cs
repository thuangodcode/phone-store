using System;

namespace PhoneStore.Application.DTOs.AI;

public class AIChatMessageDto
{
    public string Id { get; set; } = string.Empty;
    public string SessionId { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string? ToolName { get; set; }
    public string? ToolCallId { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
