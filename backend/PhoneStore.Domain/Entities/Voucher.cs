using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PhoneStore.Domain.Entities;

public class Voucher
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("code")]
    public string Code { get; set; } = null!;

    [BsonElement("description")]
    public string Description { get; set; } = string.Empty;

    [BsonElement("discountType")]
    public string DiscountType { get; set; } = "Percentage"; // Percentage | Fixed

    [BsonElement("discountValue")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal DiscountValue { get; set; }

    [BsonElement("minOrderAmount")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal MinOrderAmount { get; set; }

    [BsonElement("maxDiscount")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal MaxDiscount { get; set; }

    [BsonElement("quantity")]
    public int Quantity { get; set; }

    [BsonElement("used")]
    public int Used { get; set; }

    [BsonElement("startDate")]
    public DateTime StartDate { get; set; }

    [BsonElement("endDate")]
    public DateTime EndDate { get; set; }

    [BsonElement("isActive")]
    public bool IsActive { get; set; } = true;

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
