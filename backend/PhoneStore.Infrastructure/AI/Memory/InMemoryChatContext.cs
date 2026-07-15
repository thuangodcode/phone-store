using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using PhoneStore.Application.DTOs.AI;
using PhoneStore.Application.Interfaces.AI;

namespace PhoneStore.Infrastructure.AI.Memory;

public class InMemoryChatContext : IAIMemoryService
{
    // A simple in-memory cache mapping SessionId to a list of messages.
    // In production, this should be replaced by Redis or MongoDB.
    private readonly ConcurrentDictionary<string, List<ChatMessageDto>> _memory = new();

    public Task<List<ChatMessageDto>> GetHistoryAsync(string sessionId)
    {
        if (_memory.TryGetValue(sessionId, out var history))
        {
            return Task.FromResult(history.ToList());
        }
        return Task.FromResult(new List<ChatMessageDto>());
    }

    public Task AddMessageAsync(string sessionId, ChatMessageDto message)
    {
        _memory.AddOrUpdate(sessionId, 
            new List<ChatMessageDto> { message }, 
            (key, existingList) => 
            {
                existingList.Add(message);
                // Keep only the last 20 messages to prevent context overflow
                if (existingList.Count > 20)
                {
                    existingList.RemoveAt(0);
                }
                return existingList;
            });

        return Task.CompletedTask;
    }

    public Task ClearHistoryAsync(string sessionId)
    {
        _memory.TryRemove(sessionId, out _);
        return Task.CompletedTask;
    }
}
