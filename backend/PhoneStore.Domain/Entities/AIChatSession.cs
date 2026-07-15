using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;
using System;

namespace PhoneStore.Domain.Entities;

public class AIChatSession
{
    [BsonId]
    [BsonRepresentation(BsonType.String)]
    public string Id { get; set; } = string.Empty;

    [BsonElement("userId")]
    public string UserId { get; set; } = string.Empty;

    [BsonElement("userRole")]
    public string UserRole { get; set; } = string.Empty;

    [BsonElement("title")]
    public string Title { get; set; } = string.Empty;

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [BsonElement("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [BsonElement("deletedAt")]
    public DateTime? DeletedAt { get; set; }
}
