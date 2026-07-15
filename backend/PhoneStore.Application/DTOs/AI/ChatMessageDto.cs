using System;

namespace PhoneStore.Application.DTOs.AI;

public class ChatMessageDto
{
    public string Role { get; set; } = string.Empty; // "user", "assistant", "system", "tool"
    public string Content { get; set; } = string.Empty;
    public string? ToolCallId { get; set; } // If the message is a tool result or tool call
    public string? ToolName { get; set; }
    public string? ThoughtSignature { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
