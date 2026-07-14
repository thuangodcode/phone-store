using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PhoneStore.Domain.Entities;

public class Review
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("userId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = null!;

    [BsonElement("productId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string ProductId { get; set; } = null!;

    [BsonElement("orderId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string OrderId { get; set; } = null!;

    [BsonElement("rating")]
    public int Rating { get; set; }

    [BsonElement("comment")]
    public string Comment { get; set; } = string.Empty;

    [BsonElement("userName")]
    public string UserName { get; set; } = string.Empty;

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [BsonElement("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
