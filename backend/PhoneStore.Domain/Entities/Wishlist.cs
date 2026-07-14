using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PhoneStore.Domain.Entities;

public class Wishlist
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("userId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = null!;

    [BsonElement("productIds")]
    public List<string> ProductIds { get; set; } = new();

    [BsonElement("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
