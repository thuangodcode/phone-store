using System.Collections.Generic;
using System.Threading.Tasks;
using PhoneStore.Domain.Entities;

namespace PhoneStore.Application.Interfaces.AI;

public interface IAILogService
{
    Task LogSessionEventAsync(string sessionId, string userId, string userRole, AILogEvent logEvent);
    Task<List<AILog>> GetAllLogsAsync(int page = 1, int pageSize = 50);
    Task<AILog?> GetLogBySessionAsync(string sessionId);
}
