using System.Collections.Generic;
using System.Threading.Tasks;
using MongoDB.Driver;
using PhoneStore.Application.Interfaces.AI;
using PhoneStore.Domain.Entities;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.AI.Services;

public class AILogService : IAILogService
{
    private readonly MongoDbContext _context;

    public AILogService(MongoDbContext context)
    {
        _context = context;
    }

    public async Task LogSessionEventAsync(string sessionId, string userId, string userRole, AILogEvent logEvent)
    {
        var filter = Builders<AILog>.Filter.Eq(x => x.SessionId, sessionId);
        var update = Builders<AILog>.Update
            .SetOnInsert(x => x.SessionId, sessionId)
            .SetOnInsert(x => x.UserId, userId)
            .SetOnInsert(x => x.UserRole, userRole)
            .SetOnInsert(x => x.CreatedAt, System.DateTime.UtcNow)
            .Push(x => x.Events, logEvent);

        await _context.AILogs.UpdateOneAsync(filter, update, new UpdateOptions { IsUpsert = true });
    }

    public async Task<List<AILog>> GetAllLogsAsync(int page = 1, int pageSize = 50)
    {
        return await _context.AILogs
            .Find(_ => true)
            .SortByDescending(x => x.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync();
    }

    public async Task<AILog?> GetLogBySessionAsync(string sessionId)
    {
        return await _context.AILogs
            .Find(x => x.SessionId == sessionId)
            .FirstOrDefaultAsync();
    }
}
