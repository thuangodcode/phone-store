import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../main.dart';
import '../../../core/models/product.dart';
import '../../../core/models/cart.dart';
import '../../../core/models/wishlist.dart';
import '../../../core/services/api_service.dart';
import 'widgets/product_comments.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;

  ProductStorageVariant? _selectedStorage;
  ProductColorVariant? _selectedColor;
  String _mainImage = '';
  bool _isFavorite = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final productData = await ApiService.getProductById(widget.productId);
    if (productData == null) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Không thể tải thông tin sản phẩm. Vui lòng kiểm tra kết nối mạng.';
          _isLoading = false;
        });
      }
      return;
    }

    // Check wishlist state
    final wishlist = await ApiService.getWishlist();
    bool fav = false;
    if (wishlist != null) {
      fav = wishlist.items.any((item) => item.productId == widget.productId);
    }

    if (mounted) {
      setState(() {
        _product = productData;
        _isFavorite = fav;

        if (productData.storageVariants.isNotEmpty) {
          _selectedStorage = productData.storageVariants[0];
        }
        if (productData.colorVariants.isNotEmpty) {
          _selectedColor = productData.colorVariants[0];
        }

        if (_selectedColor != null && _selectedColor!.imageUrl.isNotEmpty) {
          _mainImage = _selectedColor!.imageUrl;
        } else if (productData.images.isNotEmpty) {
          _mainImage = productData.images[0];
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      final res = await ApiService.removeFromWishlist(widget.productId);
      if (mounted && res != null) {
        setState(() {
          _isFavorite = false;
        });
      }
    } else {
      final res = await ApiService.addToWishlist(widget.productId);
      if (mounted && res != null) {
        setState(() {
          _isFavorite = true;
        });
      }
    }
  }

  Future<void> _handleAddToCart() async {
    if (_product == null) return;

    setState(() {
      _isActionLoading = true;
    });

    final cart = await ApiService.addToCart(
      productId: _product!.id,
      quantity: 1,
      storage: _selectedStorage?.storage ?? '',
      color: _selectedColor?.name ?? '',
    );

    if (mounted) {
      setState(() {
        _isActionLoading = false;
      });

      if (cart != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm sản phẩm vào giỏ hàng thành công!'),
            backgroundColor: Color(0xFF10B981), // Emerald green success
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể thêm vào giỏ hàng. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  double _calculateCurrentPrice({bool getOriginal = false}) {
    if (_product == null) return 0.0;

    double basePrice = _product!.price;
    double salePrice = _product!.salePrice > 0
        ? _product!.salePrice
        : _product!.price;

    if (_selectedStorage != null) {
      basePrice = _selectedStorage!.price;
      salePrice = _selectedStorage!.salePrice > 0
          ? _selectedStorage!.salePrice
          : _selectedStorage!.price;
    }

    if (_selectedColor != null) {
      basePrice += _selectedColor!.priceModifier;
      salePrice += _selectedColor!.priceModifier;
    }

    return getOriginal ? basePrice : salePrice;
  }

  String _formatCurrency(double val) {
    final int intValue = val.toInt();
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

  Color _getColorBg(String colorName) {
    final name = colorName.toLowerCase();
    if (name.contains('tím') ||
        name.contains('purple') ||
        name.contains('titan tự nhiên')) {
      return const Color(0xFFC7C5D8);
    }
    if (name.contains('cam') ||
        name.contains('orange') ||
        name.contains('red') ||
        name.contains('đỏ') ||
        name.contains('titan sa mạc') ||
        name.contains('desert')) {
      return const Color(0xFFFF8B72);
    }
    if (name.contains('vàng') ||
        name.contains('yellow') ||
        name.contains('gold')) {
      return const Color(0xFFFBE8A6);
    }
    if (name.contains('đen') ||
        name.contains('black') ||
        name.contains('dark') ||
        name.contains('gray') ||
        name.contains('xám') ||
        name.contains('titan đen')) {
      return const Color(0xFF94A3B8);
    }
    if (name.contains('xanh') ||
        name.contains('blue') ||
        name.contains('green')) {
      return const Color(0xFFC5E0DC);
    }
    return const Color(0xFFE2E8F0); // Default slate color
  }

  Widget _buildProductImage(String url, {double? size, Color iconColor = Colors.white70, BoxFit fit = BoxFit.contain, Color? blendColor}) {
    if (url.isEmpty) {
      return Icon(Icons.phone_iphone, size: size ?? 32, color: iconColor);
    }
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: fit,
          color: blendColor,
          colorBlendMode: blendColor != null ? BlendMode.multiply : null,
          errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, size: size ?? 32, color: iconColor),
        );
      } catch (e) {
        return Icon(Icons.broken_image, size: size ?? 32, color: iconColor);
      }
    }
    return Image.network(
      url,
      fit: fit,
      color: blendColor,
      colorBlendMode: blendColor != null ? BlendMode.multiply : null,
      errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, size: size ?? 32, color: iconColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
          ),
        ),
      );
    }

    if (_errorMessage != null || _product == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.withOpacity(0.8),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Đã xảy ra lỗi không xác định',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loadProductDetail,
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product!;
    final double displayPrice = _calculateCurrentPrice();
    final Color headerBgColor = _getColorBg(_selectedColor?.name ?? '');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? const Color(0xFFEF4444) : Colors.white,
                size: 20,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Image Area with custom rounded shape and dynamic bg color matching mockup
                Container(
                  width: double.infinity,
                  height: 380,
                  decoration: BoxDecoration(
                    color: headerBgColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 80, bottom: 20),
                  child: Center(
                    child: Hero(
                      tag: 'product_${product.id}',
                      child: _buildProductImage(
                        _mainImage,
                        blendColor: headerBgColor,
                        iconColor: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ),
                ),

                // 2. Info area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Price Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _formatCurrency(displayPrice),
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Product Description (matches paragraph under title)
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'Trải nghiệm sức mạnh đỉnh cao và thiết kế sang trọng đẳng cấp thế giới cùng chiếc điện thoại thông minh thế hệ mới này.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Color Available section
                      if (product.colorVariants.isNotEmpty) ...[
                        Text(
                          'Màu có sẵn',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 96,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: product.colorVariants.length,
                            itemBuilder: (context, idx) {
                              final color = product.colorVariants[idx];
                              final isSelected =
                                  _selectedColor?.name == color.name;
                              final cardBgColor = _getColorBg(color.name);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = color;
                                    if (color.imageUrl.isNotEmpty) {
                                      _mainImage = color.imageUrl;
                                    }
                                  });
                                },
                                child: Container(
                                  width: 72,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: cardBgColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isDark
                                                ? Colors.white
                                                : Colors.black)
                                          : Colors.transparent,
                                      width: 2.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Center(
                                    child: _buildProductImage(
                                      color.imageUrl,
                                      size: 32,
                                      blendColor: cardBgColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 4. Storage section
                      if (product.storageVariants.isNotEmpty) ...[
                        Text(
                          'Dung lượng',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: product.storageVariants.map((storage) {
                            final isSelected =
                                _selectedStorage?.storage == storage.storage;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedStorage = storage;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? (isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.transparent)
                                      : (isDark
                                            ? const Color(0xFF1F2937)
                                            : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark
                                              ? Colors.white70
                                              : Colors.black87)
                                        : Colors.transparent,
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  storage.storage,
                                  style: TextStyle(
                                    color: isSelected
                                        ? (isDark ? Colors.white : Colors.black)
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // 5. Add to Cart button (Stadium style pill button)
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF000000),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _isActionLoading
                                ? null
                                : _handleAddToCart,
                            child: const Text(
                              'Thêm vào giỏ hàng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      ProductComments(
                        productId: product.id,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isActionLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
