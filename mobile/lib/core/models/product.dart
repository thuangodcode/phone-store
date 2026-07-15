class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double salePrice;
  final String brandId;
  final String brandName;
  final String categoryId;
  final String categoryName;
  final List<String> images;
  final int stock;
  final int sold;
  final double averageRating;
  final int totalReviews;
  final List<String> promotions;
  final List<ProductStorageVariant> storageVariants;
  final List<ProductColorVariant> colorVariants;
  final ProductSpec specifications;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.salePrice,
    required this.brandId,
    required this.brandName,
    required this.categoryId,
    required this.categoryName,
    required this.images,
    required this.stock,
    required this.sold,
    required this.averageRating,
    required this.totalReviews,
    required this.promotions,
    required this.storageVariants,
    required this.colorVariants,
    required this.specifications,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    var storageList = json['storageVariants'] as List? ?? [];
    var colorList = json['colorVariants'] as List? ?? [];
    
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      brandId: json['brandId'] ?? '',
      brandName: json['brandName'] ?? '',
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      stock: json['stock'] ?? 0,
      sold: json['sold'] ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      promotions: List<String>.from(json['promotions'] ?? []),
      storageVariants: storageList.map((x) => ProductStorageVariant.fromJson(x)).toList(),
      colorVariants: colorList.map((x) => ProductColorVariant.fromJson(x)).toList(),
      specifications: ProductSpec.fromJson(json['specifications'] ?? {}),
    );
  }
}

class ProductStorageVariant {
  final String storage;
  final double price;
  final double salePrice;

  ProductStorageVariant({
    required this.storage,
    required this.price,
    required this.salePrice,
  });

  factory ProductStorageVariant.fromJson(Map<String, dynamic> json) {
    return ProductStorageVariant(
      storage: json['storage'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProductColorVariant {
  final String name;
  final String imageUrl;
  final double priceModifier;

  ProductColorVariant({
    required this.name,
    required this.imageUrl,
    required this.priceModifier,
  });

  factory ProductColorVariant.fromJson(Map<String, dynamic> json) {
    return ProductColorVariant(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      priceModifier: (json['priceModifier'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ProductSpec {
  final String ram;
  final String rom;
  final String screenSize;
  final String battery;
  final String cpu;
  final String os;
  final String color;

  ProductSpec({
    required this.ram,
    required this.rom,
    required this.screenSize,
    required this.battery,
    required this.cpu,
    required this.os,
    required this.color,
  });

  factory ProductSpec.fromJson(Map<String, dynamic> json) {
    return ProductSpec(
      ram: json['ram'] ?? '',
      rom: json['rom'] ?? '',
      screenSize: json['screenSize'] ?? '',
      battery: json['battery'] ?? '',
      cpu: json['cpu'] ?? '',
      os: json['os'] ?? '',
      color: json['color'] ?? '',
    );
  }
}
