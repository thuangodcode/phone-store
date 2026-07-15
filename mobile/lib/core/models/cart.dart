class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<CartItem> parsedItems = itemsList.map((item) => CartItem.fromJson(item)).toList();
    
    return Cart(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      items: parsedItems,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CartItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final double salePrice;
  final int quantity;
  final int stock;
  final String storage;
  final String color;

  CartItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.salePrice,
    required this.quantity,
    required this.stock,
    required this.storage,
    required this.color,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      productImage: json['productImage'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int? ?? 1,
      stock: json['stock'] as int? ?? 0,
      storage: json['storage'] ?? '',
      color: json['color'] ?? '',
    );
  }
}
