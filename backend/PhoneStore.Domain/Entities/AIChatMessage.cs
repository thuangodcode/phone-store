using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;

namespace PhoneStore.Domain.Entities;

public class AIChatMessage
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("sessionId")]
    public string SessionId { get; set; } = string.Empty;

    [BsonElement("role")]
    public string Role { get; set; } = string.Empty;

    [BsonElement("content")]
    public string Content { get; set; } = string.Empty;

    [BsonElement("toolName")]
    public string? ToolName { get; set; }

    [BsonElement("toolCallId")]
    public string? ToolCallId { get; set; }

    [BsonElement("userId")]
    public string UserId { get; set; } = string.Empty;

    [BsonElement("userRole")]
    public string UserRole { get; set; } = string.Empty;

    [BsonElement("timestamp")]
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
}
