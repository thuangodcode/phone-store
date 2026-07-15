using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MongoDB.Driver;
using PhoneStore.Application.DTOs.AI;
using PhoneStore.Application.Interfaces.AI;
using PhoneStore.Domain.Entities;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.AI.Services;

public class AIChatSessionService : IAIChatSessionService
{
    private readonly MongoDbContext _context;

    public AIChatSessionService(MongoDbContext context)
    {
        _context = context;
    }

    public async Task<AIChatSessionDto> CreateSessionAsync(string userId, string userRole, string title, string? sessionId = null)
    {
        var id = sessionId ?? Guid.NewGuid().ToString();
        var now = DateTime.UtcNow;

        var session = new AIChatSession
        {
            Id = id,
            UserId = userId,
            UserRole = userRole,
            Title = title,
            CreatedAt = now,
            UpdatedAt = now
        };

        await _context.AIChatSessions.InsertOneAsync(session);

        return new AIChatSessionDto
        {
            Id = session.Id,
            Title = session.Title,
            UserId = session.UserId,
            UserRole = session.UserRole,
            CreatedAt = session.CreatedAt,
            UpdatedAt = session.UpdatedAt,
            DeletedAt = session.DeletedAt
        };
    }

    public async Task<AIChatSessionDto?> GetSessionAsync(string sessionId)
    {
        var session = await _context.AIChatSessions.Find(x => x.Id == sessionId).FirstOrDefaultAsync();
        if (session == null) return null;

        return new AIChatSessionDto
        {
            Id = session.Id,
            Title = session.Title,
            UserId = session.UserId,
            UserRole = session.UserRole,
            CreatedAt = session.CreatedAt,
            UpdatedAt = session.UpdatedAt,
            DeletedAt = session.DeletedAt
        };
    }

    public async Task<List<AIChatSessionDto>> GetSessionsAsync(string userId, bool includeDeleted = false)
    {
        var filter = includeDeleted
            ? Builders<AIChatSession>.Filter.Eq(x => x.UserId, userId)
            : Builders<AIChatSession>.Filter.And(
                Builders<AIChatSession>.Filter.Eq(x => x.UserId, userId),
                Builders<AIChatSession>.Filter.Eq(x => x.DeletedAt, null));

        var sessions = await _context.AIChatSessions
            .Find(filter)
            .SortByDescending(x => x.UpdatedAt)
            .ToListAsync();

        return sessions.Select(session => new AIChatSessionDto
        {
            Id = session.Id,
            Title = session.Title,
            UserId = session.UserId,
            UserRole = session.UserRole,
            CreatedAt = session.CreatedAt,
            UpdatedAt = session.UpdatedAt,
            DeletedAt = session.DeletedAt
        }).ToList();
    }

    public async Task<List<AIChatMessageDto>> GetSessionMessagesAsync(string sessionId)
    {
        var messages = await _context.AIChatMessages
            .Find(x => x.SessionId == sessionId)
            .SortBy(x => x.Timestamp)
            .ToListAsync();

        return messages.Select(message => new AIChatMessageDto
        {
            Id = message.Id,
            SessionId = message.SessionId,
            Role = message.Role,
            Content = message.Content,
            ToolName = message.ToolName,
            ToolCallId = message.ToolCallId,
            Timestamp = message.Timestamp
        }).ToList();
    }

    public async Task<AIChatSessionDto?> UpdateSessionAsync(string sessionId, string? title = null, DateTime? deletedAt = null)
    {
        var update = Builders<AIChatSession>.Update
            .Set(x => x.UpdatedAt, DateTime.UtcNow);

        if (title != null)
        {
            update = update.Set(x => x.Title, title);
        }

        if (deletedAt != null)
        {
            update = update.Set(x => x.DeletedAt, deletedAt);
        }

        await _context.AIChatSessions.UpdateOneAsync(x => x.Id == sessionId, update);
        return await GetSessionAsync(sessionId);
    }
}
