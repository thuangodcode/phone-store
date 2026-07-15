namespace PhoneStore.Application.DTOs.AI;

public class AIChatRequestDto
{
    public string Message { get; set; } = string.Empty;
    public string? SessionId { get; set; }
}
