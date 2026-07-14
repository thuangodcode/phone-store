using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PhoneStore.Domain.Entities;

public class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("fullName")]
    public string FullName { get; set; } = null!;

    [BsonElement("email")]
    public string Email { get; set; } = null!;

    [BsonElement("phone")]
    public string Phone { get; set; } = string.Empty;

    [BsonElement("password")]
    public string Password { get; set; } = null!;

    [BsonElement("role")]
    public string Role { get; set; } = "Customer";

    [BsonElement("address")]
    public string Address { get; set; } = string.Empty;

    [BsonElement("avatar")]
    public string Avatar { get; set; } = string.Empty;

    [BsonElement("isActive")]
    public bool IsActive { get; set; } = true;

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [BsonElement("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
