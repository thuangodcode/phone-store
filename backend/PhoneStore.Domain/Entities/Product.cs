using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace PhoneStore.Domain.Entities;

public class Product
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = null!;

    [BsonElement("name")]
    public string Name { get; set; } = null!;

    [BsonElement("description")]
    public string Description { get; set; } = string.Empty;

    [BsonElement("price")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal Price { get; set; }

    [BsonElement("salePrice")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal SalePrice { get; set; }

    [BsonElement("brandId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string BrandId { get; set; } = null!;

    [BsonElement("categoryId")]
    [BsonRepresentation(BsonType.ObjectId)]
    public string CategoryId { get; set; } = null!;

    [BsonElement("images")]
    public List<string> Images { get; set; } = new();

    [BsonElement("specifications")]
    public ProductSpecification Specifications { get; set; } = new();

    [BsonElement("storageVariants")]
    public List<ProductStorageVariant> StorageVariants { get; set; } = new();

    [BsonElement("colorVariants")]
    public List<ProductColorVariant> ColorVariants { get; set; } = new();

    [BsonElement("promotions")]
    public List<string> Promotions { get; set; } = new();

    [BsonElement("stock")]
    public int Stock { get; set; }

    [BsonElement("sold")]
    public int Sold { get; set; }

    [BsonElement("averageRating")]
    public double AverageRating { get; set; }

    [BsonElement("totalReviews")]
    public int TotalReviews { get; set; }

    [BsonElement("isActive")]
    public bool IsActive { get; set; } = true;

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [BsonElement("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class ProductSpecification
{
    [BsonElement("ram")]
    public string Ram { get; set; } = string.Empty;

    [BsonElement("rom")]
    public string Rom { get; set; } = string.Empty;

    [BsonElement("screenSize")]
    public string ScreenSize { get; set; } = string.Empty;

    [BsonElement("battery")]
    public string Battery { get; set; } = string.Empty;

    [BsonElement("cpu")]
    public string Cpu { get; set; } = string.Empty;

    [BsonElement("os")]
    public string Os { get; set; } = string.Empty;

    [BsonElement("color")]
    public string Color { get; set; } = string.Empty;
}

public class ProductStorageVariant
{
    [BsonElement("storage")]
    public string Storage { get; set; } = string.Empty;

    [BsonElement("price")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal Price { get; set; }

    [BsonElement("salePrice")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal SalePrice { get; set; }
}

public class ProductColorVariant
{
    [BsonElement("name")]
    public string Name { get; set; } = string.Empty;

    [BsonElement("imageUrl")]
    public string ImageUrl { get; set; } = string.Empty;

    [BsonElement("priceModifier")]
    [BsonRepresentation(BsonType.Decimal128)]
    public decimal PriceModifier { get; set; }
}
