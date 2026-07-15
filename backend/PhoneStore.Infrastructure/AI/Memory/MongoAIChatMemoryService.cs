using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using MongoDB.Driver;
using PhoneStore.Application.DTOs.AI;
using PhoneStore.Application.Interfaces.AI;
using PhoneStore.Domain.Entities;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.AI.Memory;

public class MongoAIChatMemoryService : IAIMemoryService
{
    private readonly MongoDbContext _context;

    public MongoAIChatMemoryService(MongoDbContext context)
    {
        _context = context;
    }

    public async Task<List<ChatMessageDto>> GetHistoryAsync(string sessionId)
    {
        var messages = await _context.AIChatMessages
            .Find(x => x.SessionId == sessionId)
            .SortBy(x => x.Timestamp)
            .ToListAsync();

        return messages.Select(x => new ChatMessageDto
        {
            Role = x.Role,
            Content = x.Content,
            ToolName = x.ToolName,
            ToolCallId = x.ToolCallId,
            Timestamp = x.Timestamp
        }).ToList();
    }

    public async Task AddMessageAsync(string sessionId, ChatMessageDto message)
    {
        var entity = new AIChatMessage
        {
            SessionId = sessionId,
            Role = message.Role,
            Content = message.Content,
            ToolName = message.ToolName,
            ToolCallId = message.ToolCallId,
            Timestamp = message.Timestamp == default ? DateTime.UtcNow : message.Timestamp,
            UserId = string.Empty,
            UserRole = string.Empty
        };

        await _context.AIChatMessages.InsertOneAsync(entity);
    }

    public async Task ClearHistoryAsync(string sessionId)
    {
        await _context.AIChatMessages.DeleteManyAsync(x => x.SessionId == sessionId);
    }
}
