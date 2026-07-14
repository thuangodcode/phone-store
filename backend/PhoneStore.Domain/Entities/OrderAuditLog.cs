using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PhoneStore.Domain.Entities;

public class OrderAuditLog
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("orderId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string OrderId { get; set; } = null!;

    [BsonElement("staffId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string StaffId { get; set; } = null!;

    [BsonElement("staffName")]
    public string StaffName { get; set; } = null!;

    [BsonElement("action")]
    public string Action { get; set; } = null!; // e.g., "UpdatedStatus", "UpdatedPaymentStatus", "CollectedPayment"

    [BsonElement("details")]
    public string Details { get; set; } = null!; // Detailed message: "Nhân viên 1 đã thu tiền đơn hàng #123, số tiền: 500.000đ"

    [BsonElement("timestamp")]
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    [BsonElement("oldValue")]
    public string? OldValue { get; set; }

    [BsonElement("newValue")]
    public string? NewValue { get; set; }
}
