using System;
using System.Collections.Generic;
using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PhoneStore.Domain.Entities;

public class AILog
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;
    public string SessionId { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string UserRole { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public List<AILogEvent> Events { get; set; } = new();
}

public class AILogEvent
{
    public string EventType { get; set; } = string.Empty; // e.g. PROMPT_COMPILED, LLM_RESPONSE, TOOL_EXECUTION
    public string Description { get; set; } = string.Empty;
    public string RawData { get; set; } = string.Empty; // JSON formatted payload
    public long LatencyMs { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
