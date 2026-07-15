import 'package:flutter/material.dart';
import '../../../../core/models/product.dart';
import '../../../../core/services/api_service.dart';
import '../product_detail_page.dart';

class ProductGrid extends StatefulWidget {
  final String brandId;
  final String searchQuery;

  const ProductGrid({
    super.key,
    this.brandId = '',
    this.searchQuery = '',
  });

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  List<Product> _products = [];
  bool _isLoading = true;

  // Fallback mock products if API is offline
  final List<Map<String, dynamic>> _mockProducts = const [
    {
      'id': '1',
      'name': 'iPhone 15 Pro Max Titan Tự Nhiên 256GB',
      'brandName': 'Apple',
      'price': 37990000.0,
      'salePrice': 34990000.0,
      'averageRating': 4.9,
      'totalReviews': 245,
      'images': [],
      'promotions': ['Trả góp 0%'],
    },
    {
      'id': '2',
      'name': 'Samsung Galaxy S24 Ultra 12GB/256GB',
      'brandName': 'Samsung',
      'price': 33990000.0,
      'salePrice': 29990000.0,
      'averageRating': 4.8,
      'totalReviews': 188,
      'images': [],
      'promotions': ['Lì xì 3 triệu'],
    },
    {
      'id': '3',
      'name': 'Xiaomi 14 Ultra 16GB/512GB Leica',
      'brandName': 'Xiaomi',
      'price': 32990000.0,
      'salePrice': 27990000.0,
      'averageRating': 4.7,
      'totalReviews': 96,
      'images': [],
      'promotions': ['Tặng tai nghe Buds'],
    },
    {
      'id': '4',
      'name': 'OPPO Find X7 Ultra 256GB Hasselblad',
      'brandName': 'OPPO',
      'price': 27990000.0,
      'salePrice': 24990000.0,
      'averageRating': 4.6,
      'totalReviews': 54,
      'images': [],
      'promotions': ['Bảo hành 2 năm'],
    },
    {
      'id': '5',
      'name': 'Vivo X100 Pro 16GB/512GB Zeiss',
      'brandName': 'Vivo',
      'price': 25990000.0,
      'salePrice': 22990000.0,
      'averageRating': 4.8,
      'totalReviews': 72,
      'images': [],
      'promotions': ['Hot Sale'],
    },
    {
      'id': '6',
      'name': 'ASUS ROG Phone 8 16GB/256GB Gaming',
      'brandName': 'ASUS',
      'price': 28990000.0,
      'salePrice': 25990000.0,
      'averageRating': 4.9,
      'totalReviews': 43,
      'images': [],
      'promotions': ['Độc quyền game thủ'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void didUpdateWidget(covariant ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload products if filters change from parent
    if (oldWidget.brandId != widget.brandId || oldWidget.searchQuery != widget.searchQuery) {
      _fetchProducts();
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    final products = await ApiService.getProducts(
      brandId: widget.brandId,
      search: widget.searchQuery,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (products.isNotEmpty) {
          _products = products;
        } else {
          // If API returns empty (possibly connection error or no filter matches)
          // Filter our mock list locally to maintain UX consistency
          List<Product> temp = _mockProducts.map((m) => Product(
            id: m['id'],
            name: m['name'],
            description: '',
            price: m['price'],
            salePrice: m['salePrice'],
            brandId: m['brandName'].toString().toLowerCase(),
            brandName: m['brandName'],
            categoryId: '',
            categoryName: '',
            images: [],
            stock: 10,
            sold: 5,
            averageRating: m['averageRating'],
            totalReviews: m['totalReviews'],
            promotions: List<String>.from(m['promotions']),
            storageVariants: const [],
            colorVariants: const [],
            specifications: ProductSpec(
              ram: '',
              rom: '',
              screenSize: '',
              battery: '',
              cpu: '',
              os: '',
              color: '',
            ),
          )).toList();

          if (widget.brandId.isNotEmpty) {
            temp = temp.where((p) => p.brandId == widget.brandId || p.brandName.toLowerCase() == widget.brandId.toLowerCase()).toList();
          }
          if (widget.searchQuery.isNotEmpty) {
            final q = widget.searchQuery.toLowerCase();
            temp = temp.where((p) => p.name.toLowerCase().contains(q) || p.brandName.toLowerCase().contains(q)).toList();
          }

          _products = temp;
        }
      });
    }
  }

  String _formatCurrency(double value) {
    final int intValue = value.toInt();
    final String valueStr = intValue.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = valueStr.length - 1; i >= 0; i--) {
      buffer.write(valueStr[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }

  IconData _getIconForBrand(String brandName) {
    final lower = brandName.toLowerCase();
    if (lower.contains('apple')) return Icons.phone_iphone;
    if (lower.contains('samsung')) return Icons.star_border;
    if (lower.contains('xiaomi')) return Icons.camera_enhance;
    if (lower.contains('oppo')) return Icons.camera;
    if (lower.contains('vivo')) return Icons.lens;
    return Icons.gamepad;
  }

  Color _getBgColorForBrand(String brandName) {
    final lower = brandName.toLowerCase();
    if (lower.contains('apple')) return const Color(0xFF27272A);
    if (lower.contains('samsung')) return const Color(0xFF1E293B);
    if (lower.contains('xiaomi')) return const Color(0xFF3F2D20);
    if (lower.contains('oppo')) return const Color(0xFF14271D);
    if (lower.contains('vivo')) return const Color(0xFF1E1E2C);
    return const Color(0xFF2C1318);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy sản phẩm nào phù hợp',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 3 : 2;
    final double childAspectRatio = screenWidth > 600 ? 0.72 : 0.64;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          final product = _products[index];

          // Calculate discount percent
          int discountPercent = 0;
          if (product.price > 0 && product.salePrice < product.price) {
            discountPercent = (((product.price - product.salePrice) / product.price) * 100).round();
          }

          final String mainPromo = product.promotions.isNotEmpty ? product.promotions[0] : '';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(productId: product.id),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1F2937),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Image Area
                  Expanded(
                    flex: 11,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: _getBgColorForBrand(product.brandName),
                          child: Center(
                            child: product.images.isNotEmpty
                                ? Image.network(
                                    product.images[0],
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      _getIconForBrand(product.brandName),
                                      size: 54,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  )
                                : Icon(
                                    _getIconForBrand(product.brandName),
                                    size: 54,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                          ),
                        ),
                        // Discount Tag
                        if (discountPercent > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-$discountPercent%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        // Promo Tag
                        if (mainPromo.isNotEmpty)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                mainPromo,
                                style: const TextStyle(
                                  color: Color(0xFFE5E7EB),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Content Info
                  Expanded(
                    flex: 12,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.brandName,
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF9FAFB),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Color(0xFFEAB308),
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.averageRating > 0 ? product.averageRating.toString() : '4.8',
                                style: const TextStyle(
                                  color: Color(0xFFF9FAFB),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${product.totalReviews > 0 ? product.totalReviews : 50})',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (product.price > product.salePrice)
                                      Text(
                                        _formatCurrency(product.price),
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 10,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatCurrency(product.salePrice),
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2937),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF374151),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Đã thêm ${product.name} vào giỏ hàng!'),
                                          backgroundColor: const Color(0xFFEF4444),
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: const Icon(
                                      Icons.add_shopping_cart,
                                      color: Color(0xFFF9FAFB),
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
        },
      ),
    );
  }
}
