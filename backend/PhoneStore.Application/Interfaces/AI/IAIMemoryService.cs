using System.Collections.Generic;
using System.Threading.Tasks;
using PhoneStore.Application.DTOs.AI;

namespace PhoneStore.Application.Interfaces.AI;

public interface IAIMemoryService
{
    Task<List<ChatMessageDto>> GetHistoryAsync(string sessionId);
    Task AddMessageAsync(string sessionId, ChatMessageDto message);
    Task ClearHistoryAsync(string sessionId);
}
