using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using PhoneStore.Application.DTOs.AI;

namespace PhoneStore.Application.Interfaces.AI;

public interface IAIChatSessionService
{
    Task<List<AIChatSessionDto>> GetSessionsAsync(string userId, bool includeDeleted = false);
    Task<AIChatSessionDto> CreateSessionAsync(string userId, string userRole, string title, string? sessionId = null);
    Task<AIChatSessionDto?> GetSessionAsync(string sessionId);
    Task<AIChatSessionDto?> UpdateSessionAsync(string sessionId, string? title = null, DateTime? deletedAt = null);
    Task<List<AIChatMessageDto>> GetSessionMessagesAsync(string sessionId);
}
