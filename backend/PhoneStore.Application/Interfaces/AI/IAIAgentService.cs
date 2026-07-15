using System.Threading.Tasks;
using PhoneStore.Application.DTOs.AI;

namespace PhoneStore.Application.Interfaces.AI;

public interface IAIAgentService
{
    Task<AIChatResponseDto> ProcessChatAsync(AIChatRequestDto request, string userId, string role);
}
