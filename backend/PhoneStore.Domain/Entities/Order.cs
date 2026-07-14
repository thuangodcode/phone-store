using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PhoneStore.Domain.Entities;

public class Order
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("userId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string UserId { get; set; } = null!;

    [BsonElement("items")]
    public List<OrderItem> Items { get; set; } = new();

    [BsonElement("totalAmount")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal TotalAmount { get; set; }

    [BsonElement("discountAmount")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal DiscountAmount { get; set; }

    [BsonElement("finalAmount")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal FinalAmount { get; set; }

    [BsonElement("voucherCode")]
    public string? VoucherCode { get; set; }

    [BsonElement("shippingAddress")]
    public string ShippingAddress { get; set; } = null!;

    [BsonElement("phone")]
    public string Phone { get; set; } = null!;

    [BsonElement("receiverName")]
    public string ReceiverName { get; set; } = null!;

    [BsonElement("status")]
    public string Status { get; set; } = "Pending";

    [BsonElement("paymentMethod")]
    public string PaymentMethod { get; set; } = "COD";

    [BsonElement("note")]
    public string Note { get; set; } = string.Empty;

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [BsonElement("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class OrderItem
{
    [BsonElement("productId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string ProductId { get; set; } = null!;

    [BsonElement("productName")]
    public string ProductName { get; set; } = null!;

    [BsonElement("productImage")]
    public string ProductImage { get; set; } = string.Empty;

    [BsonElement("quantity")]
    public int Quantity { get; set; }

    [BsonElement("price")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal Price { get; set; }
}
