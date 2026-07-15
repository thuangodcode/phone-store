class Wishlist {
  final String id;
  final String userId;
  final List<WishlistItem> items;

  Wishlist({
    required this.id,
    required this.userId,
    required this.items,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<WishlistItem> parsedItems = itemsList.map((item) => WishlistItem.fromJson(item)).toList();

    return Wishlist(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: parsedItems,
    );
  }
}

class WishlistItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final double salePrice;
  final bool inStock;

  WishlistItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.salePrice,
    required this.inStock,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      inStock: json['inStock'] as bool? ?? true,
    );
  }
}
