import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'home_page.dart';
import 'product_detail_page.dart';
import 'widgets/dock_navigation_bar.dart';
import '../../../core/models/user_info.dart';
import '../../../core/models/product.dart';
import '../../../core/models/cart.dart';
import '../../../core/models/wishlist.dart';
import '../../../core/services/api_service.dart';
import '../../auth/presentation/login_page.dart';
import '../../../../main.dart';
import 'settings_page.dart';
import 'checkout_page.dart';
import 'order_history_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const CartTab(),
      const SearchTab(),
      const WishlistTab(),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712), // Background dark Gray 950
      body: Stack(
        children: [
          // Screen Content Area
          IndexedStack(index: _currentIndex, children: _pages),

          // Floating Dock Navigation Bar at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 24.0,
              ), // Margin bottom from safe area
              child: DockNavigationBar(
                currentIndex: _currentIndex,
                onTabSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// MÀN HÌNH MOCKUP CHO CÁC TAB KHÁC
// (Thiết kế Dark Mode đồng bộ và sang trọng)
// ==========================================

// 1. Tab Giỏ Hàng (Cart Tab)
class CartTab extends StatefulWidget {
  const CartTab({super.key});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  Cart? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
    });
    final cartData = await ApiService.getCart();
    if (mounted) {
      setState(() {
        _cart = cartData;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(String productId, int newQty) async {
    if (newQty < 1) {
      _removeItem(productId);
      return;
    }
    final updatedCart = await ApiService.updateCartItem(
      productId: productId,
      quantity: newQty,
    );
    if (mounted && updatedCart != null) {
      setState(() {
        _cart = updatedCart;
      });
    }
  }

  Future<void> _removeItem(String productId) async {
    final updatedCart = await ApiService.removeFromCart(productId);
    if (mounted && updatedCart != null) {
      setState(() {
        _cart = updatedCart;
      });
    }
  }

  Future<void> _clearCart() async {
    final success = await ApiService.clearCart();
    if (success && mounted) {
      setState(() {
        _cart = null;
      });
    }
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

    final cartItems = _cart?.items ?? [];
    double totalAmount = 0.0;
    for (final item in cartItems) {
      final priceToUse = item.salePrice > 0 ? item.salePrice : item.price;
      totalAmount += priceToUse * item.quantity;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Giỏ hàng cá nhân',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Color(0xFFEF4444)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xác nhận'),
                    content: const Text('Bạn có chắc chắn muốn xóa toàn bộ sản phẩm trong giỏ hàng?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearCart();
                        },
                        child: const Text('Xóa sạch', style: TextStyle(color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Giỏ hàng của bạn đang trống',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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
                    onPressed: () {
                      // Hỗ trợ click mua sắm
                    },
                    child: const Text(
                      'MUA SẮM NGAY',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.72 : 0.58,
                      ),
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return _buildCartItemWidget(item);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Billing Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tạm tính',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalAmount),
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Giảm giá (Voucher)',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '- 0 đ',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF1F2937), height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng thanh toán',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatCurrency(totalAmount),
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                             onPressed: () {
                               if (_cart != null) {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(
                                     builder: (context) => CheckoutPage(
                                       cart: _cart!,
                                       onOrderSuccess: () {
                                         setState(() {
                                           _cart = null;
                                         });
                                         _loadCart();
                                       },
                                     ),
                                   ),
                                 );
                               }
                             },
                            child: const Text(
                              'TIẾN HÀNH ĐẶT HÀNG',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 90), // Space for Floating Dock
                ],
              ),
            ),
    );
  }

  Widget _buildCartItemWidget(CartItem item) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productId: item.productId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Area similar to HomePage
              Expanded(
                flex: 12,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: _getBgColorForBrand(item.productName.split(' ')[0], isDark),
                      child: Center(
                        child: item.productImage.isNotEmpty
                            ? Image.network(
                                item.productImage,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  _getIconForBrand(item.productName),
                                  size: 48,
                                  color: isDark ? Colors.white70 : const Color(0xFFEF4444),
                                ),
                              )
                            : Icon(
                                _getIconForBrand(item.productName),
                                size: 48,
                                color: isDark ? Colors.white70 : const Color(0xFFEF4444),
                              ),
                      ),
                    ),
                    // Delete Button on Top Right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeItem(item.productId),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info Area
              Expanded(
                flex: 13,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (item.color.isNotEmpty || item.storage.isNotEmpty)
                        Text(
                          '${item.storage} | ${item.color}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 10,
                          ),
                        ),
                      const Spacer(),
                      // Price formatted like HomePage (đ)
                      if (item.salePrice > 0 && item.price > item.salePrice)
                        Text(
                          _formatCurrency(item.price),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 9,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      Text(
                        _formatCurrency(item.salePrice > 0 ? item.salePrice : item.price),
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Quantity adjust buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQtyBtn(
                            Icons.remove,
                            onTap: () => _updateQuantity(item.productId, item.quantity - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          _buildQtyBtn(
                            Icons.add,
                            onTap: () => _updateQuantity(item.productId, item.quantity + 1),
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
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, {required VoidCallback onTap}) {
    final isDark = themeManager.isDarkMode;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
          size: 14,
        ),
      ),
    );
  }
}

// 2. Tab Tìm Kiếm (Search Tab)
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _controller = TextEditingController();
  List<Product> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await ApiService.getProducts(search: query);
    
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Tìm kiếm sản phẩm',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Field
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Color(0xFF6B7280)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      onSubmitted: _performSearch,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tên dòng máy, hãng sản xuất...',
                        hintStyle: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF6B7280), size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _searchResults.clear();
                          _hasSearched = false;
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (!_hasSearched) ...[
              // Hot Keywords
              Text(
                'Từ khóa hot nhất',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag('iPhone'),
                  _buildTag('Samsung'),
                  _buildTag('Xiaomi'),
                  _buildTag('ROG Phone'),
                  _buildTag('Oppo'),
                  _buildTag('Ultra'),
                ],
              ),
              const SizedBox(height: 32),
              // Search Illustration Mockup
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.youtube_searched_for,
                        size: 64,
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tìm kiếm nhanh hơn bằng cách nhập từ khóa hoặc chọn thẻ hot',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_isLoading) ...[
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                  ),
                ),
              ),
            ] else if (_searchResults.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Không tìm thấy sản phẩm nào phù hợp',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Kết quả tìm kiếm (${_searchResults.length})',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _searchResults.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.72 : 0.64,
                  ),
                  itemBuilder: (context, index) {
                    final product = _searchResults[index];
                    return _buildSearchResultItem(product);
                  },
                ),
              ),
            ],
            const SizedBox(height: 90), // Space for Floating Dock
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Product product) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);

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
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
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
                      color: _getBgColorForBrand(product.brandName, isDark),
                      child: Center(
                        child: product.images.isNotEmpty
                            ? Image.network(
                                product.images[0],
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  _getIconForBrand(product.brandName),
                                  size: 54,
                                  color: isDark ? Colors.white70 : const Color(0xFFEF4444),
                                ),
                              )
                            : Icon(
                                _getIconForBrand(product.brandName),
                                size: 54,
                                color: isDark ? Colors.white70 : const Color(0xFFEF4444),
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
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
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
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
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
                              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  final updatedCart = await ApiService.addToCart(
                                    productId: product.id,
                                    quantity: 1,
                                    color: "",
                                    storage: "",
                                  );
                                  final success = updatedCart != null;
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? 'Đã thêm ${product.name} vào giỏ hàng!' : 'Thêm vào giỏ hàng thất bại'),
                                        backgroundColor: success ? const Color(0xFFEF4444) : Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Icon(
                                  Icons.add_shopping_cart,
                                  color: theme.colorScheme.onSurface,
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
      ),
    );
  }

  Widget _buildTag(String text) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _performSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// 3. Tab Danh Sách Yêu Thích (Wishlist Tab)
class WishlistTab extends StatefulWidget {
  const WishlistTab({super.key});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab> {
  Wishlist? _wishlist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
    });
    final wishlistData = await ApiService.getWishlist();
    if (mounted) {
      setState(() {
        _wishlist = wishlistData;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFromWishlist(String productId) async {
    final updatedWishlist = await ApiService.removeFromWishlist(productId);
    if (mounted && updatedWishlist != null) {
      setState(() {
        _wishlist = updatedWishlist;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa khỏi danh sách yêu thích'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 1),
        ),
      );
    }
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

    final items = _wishlist?.items ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Danh sách yêu thích',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có sản phẩm yêu thích nào',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                  child: Text(
                    'SẢN PHẨM BẠN QUAN TÂM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: MediaQuery.of(context).size.width > 600 ? 0.72 : 0.64,
                      ),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildWishlistItemWidget(item);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 90),
              ],
            ),
    );
  }

  Widget _buildWishlistItemWidget(WishlistItem item) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(productId: item.productId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Area similar to HomePage
              Expanded(
                flex: 12,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: _getBgColorForBrand(item.productName.split(' ')[0], isDark),
                      child: Center(
                        child: item.productImage.isNotEmpty
                            ? Image.network(
                                item.productImage,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  _getIconForBrand(item.productName),
                                  size: 48,
                                  color: isDark ? Colors.white70 : const Color(0xFFEF4444),
                                ),
                              )
                            : Icon(
                                _getIconForBrand(item.productName),
                                size: 48,
                                color: isDark ? Colors.white70 : const Color(0xFFEF4444),
                              ),
                      ),
                    ),
                    // Heart Button on Top Right (to remove)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _removeFromWishlist(item.productId),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Color(0xFFEF4444),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info Area
              Expanded(
                flex: 13,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                item.inStock ? Icons.check_circle_outline : Icons.remove_circle_outline,
                                color: item.inStock ? Colors.green : Colors.red,
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.inStock ? 'Còn hàng' : 'Hết hàng',
                                style: TextStyle(
                                  color: item.inStock ? Colors.green : Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Price formatted like HomePage (đ)
                          if (item.salePrice > 0 && item.price > item.salePrice)
                            Text(
                              _formatCurrency(item.price),
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 9,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            _formatCurrency(item.salePrice > 0 ? item.salePrice : item.price),
                            style: const TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Add to Cart Button on Bottom Right similar to HomePage
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () async {
                          final updatedCart = await ApiService.addToCart(
                            productId: item.productId,
                            quantity: 1,
                            color: "",
                            storage: "",
                          );
                          final success = updatedCart != null;
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success ? 'Đã thêm vào giỏ hàng!' : 'Thêm vào giỏ hàng thất bại'),
                                backgroundColor: success ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(19),
                            ),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 4. Tab Tài Khoản (Profile Tab)
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserInfo? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await ApiService.getSavedUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Đăng xuất', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất tài khoản?', style: TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  Widget _buildAvatarWidget(String avatar, String displayName, bool isDark, {double size = 90.0, double fontSize = 32.0}) {
    String getInitials(String name) {
      if (name.isEmpty) return 'U';
      final parts = name.trim().split(' ');
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }

    if (avatar.isNotEmpty) {
      if (avatar.startsWith('data:image') && avatar.contains('base64,')) {
        try {
          final base64Str = avatar.split('base64,')[1];
          final bytes = base64.decode(base64Str);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: size / 2,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                child: Text(
                  getInitials(displayName),
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          );
        } catch (e) {
          // Fallback
        }
      } else if (Uri.tryParse(avatar)?.hasAbsolutePath == true) {
        return ClipOval(
          child: Image.network(
            avatar,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CircleAvatar(
              radius: size / 2,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              child: Text(
                getInitials(displayName),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        );
      }
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      child: Text(
        getInitials(displayName),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFFEF4444),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog({
    required String fullName,
    required String phone,
    required String address,
    required String avatar,
  }) async {
    final isDark = themeManager.isDarkMode;

    final nameController = TextEditingController(text: fullName);
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController(text: address);
    String selectedAvatar = avatar;

    final formKey = GlobalKey<FormState>();
    final picker = ImagePicker();
    bool isSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFFEF4444),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cập nhật hồ sơ',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chọn ảnh đại diện bằng Image Picker
                      Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFEF4444).withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: _buildAvatarWidget(selectedAvatar, fullName, isDark, size: 80, fontSize: 28),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: isSaving ? null : () async {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 40,
                                    maxWidth: 400,
                                    maxHeight: 400,
                                  );
                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    final base64String = 'data:image/jpeg;base64,${base64.encode(bytes)}';
                                    setStateDialog(() {
                                      selectedAvatar = base64String;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFFEF4444)),
                                label: const Text('Thư viện', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                onPressed: isSaving ? null : () async {
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.camera,
                                    imageQuality: 40,
                                    maxWidth: 400,
                                    maxHeight: 400,
                                  );
                                  if (image != null) {
                                    final bytes = await image.readAsBytes();
                                    final base64String = 'data:image/jpeg;base64,${base64.encode(bytes)}';
                                    setStateDialog(() {
                                      selectedAvatar = base64String;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFFEF4444)),
                                label: const Text('Chụp ảnh', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Họ tên
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Họ và tên',
                          labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                          hintText: 'Nhập họ và tên',
                          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFEF4444)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Số điện thoại
                      TextFormField(
                        controller: phoneController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại',
                          labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                          hintText: 'Nhập số điện thoại',
                          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                          prefixIcon: const Icon(Icons.phone_iphone_rounded, color: Color(0xFFEF4444)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Địa chỉ
                      TextFormField(
                        controller: addressController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ giao hàng',
                          labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                          hintText: 'Nhập địa chỉ của bạn',
                          hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                          prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFFEF4444)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập địa chỉ';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setStateDialog(() {
                              isSaving = true;
                            });

                            final result = await ApiService.updateProfile(
                              fullName: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              address: addressController.text.trim(),
                              avatar: selectedAvatar,
                            );

                            if (mounted) {
                              Navigator.pop(context); // Đóng dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? ''),
                                  backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                ),
                              );

                              if (result['success'] == true) {
                                _loadUserProfile(); // Load lại thông tin
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
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

    final String displayName = _currentUser?.fullName ?? 'Chi Nguyễn';
    final String displayEmail = _currentUser?.email ?? 'customer.chinyuyen@gmail.com';
    final String displayPhone = _currentUser?.phone ?? 'Chưa thiết lập';
    final String displayAddress = _currentUser?.address ?? 'Chưa thiết lập';
    final String displayAvatar = _currentUser?.avatar ?? '';

    // Lấy ký tự viết tắt của tên để làm avatar placeholder
    String getInitials(String name) {
      if (name.isEmpty) return 'U';
      final parts = name.trim().split(' ');
      if (parts.length > 1) {
        return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      }
      return name[0].toUpperCase();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Custom Header with Gradient
            Stack(
              children: [
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E1B4B), // Indigo 900
                              const Color(0xFF311042), // Deep purple
                              const Color(0xFF581C87), // Purple 900
                            ]
                          : [
                              const Color(0xFFFCA5A5), // Red 300
                              const Color(0xFFEF4444), // Red 500
                              const Color(0xFFB91C1C), // Red 700
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                // Settings button on top right
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_rounded, color: Colors.white, size: 24),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SettingsPage()),
                        ).then((_) {
                          // Force rebuild khi từ trang Cài đặt quay lại để update theme
                          setState(() {});
                        });
                      },
                    ),
                  ),
                ),
                // Profile Main details inside header
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _buildAvatarWidget(displayAvatar, displayName, isDark),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                        label: const Text('Sửa hồ sơ', style: TextStyle(color: Colors.white, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _showEditProfileDialog(
                          fullName: displayName,
                          phone: displayPhone == 'Chưa thiết lập' ? '' : displayPhone,
                          address: displayAddress == 'Chưa thiết lập' ? '' : displayAddress,
                          avatar: displayAvatar,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Section 1: Thông tin cá nhân
                  _buildSectionTitle(context, 'THÔNG TIN CHI TIẾT'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            context,
                            icon: Icons.person_outline_rounded,
                            label: 'Họ và tên',
                            value: displayName,
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                          _buildDetailRow(
                            context,
                            icon: Icons.email_outlined,
                            label: 'Địa chỉ Email',
                            value: displayEmail,
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                          _buildDetailRow(
                            context,
                            icon: Icons.phone_iphone_rounded,
                            label: 'Số điện thoại',
                            value: displayPhone,
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                          _buildDetailRow(
                            context,
                            icon: Icons.location_on_outlined,
                            label: 'Địa chỉ giao hàng',
                            value: displayAddress,
                            isMultiLine: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section 2: Tiện ích & Cài đặt
                  _buildSectionTitle(context, 'TIỆN ÍCH & THIẾT LẬP'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            context,
                            icon: Icons.history_rounded,
                            title: 'Lịch sử mua hàng',
                            subtitle: 'Đơn hàng, Hóa đơn thanh toán',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                          _buildMenuItem(
                            context,
                            icon: Icons.discount_outlined,
                            title: 'Kho Voucher của tôi',
                            subtitle: 'Ưu đãi & giảm giá độc quyền',
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                          _buildMenuItem(
                            context,
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Lịch sử chat hỗ trợ',
                            subtitle: 'SignalR & Trợ lý AI logs',
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                          _buildMenuItem(
                            context,
                            icon: Icons.settings_outlined,
                            title: 'Cài đặt hệ thống',
                            subtitle: 'Chuyển đổi giao diện Sáng / Tối',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsPage()),
                              ).then((_) {
                                setState(() {});
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section 3: Đăng xuất
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleLogout,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x1AEF4444) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Đăng xuất tài khoản',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 120), // Bottom padding for float dock
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFEF4444),
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: isMultiLine ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
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

Color _getBgColorForBrand(String brandName, bool isDark) {
  final lower = brandName.toLowerCase();
  if (lower.contains('apple')) return const Color(0xFF27272A);
  if (lower.contains('samsung')) return const Color(0xFF1E293B);
  if (lower.contains('xiaomi')) return const Color(0xFF3F2D20);
  if (lower.contains('oppo')) return const Color(0xFF14271D);
  if (lower.contains('vivo')) return const Color(0xFF1E1E2C);
  return isDark ? const Color(0xFF2C1318) : const Color(0xFFFEE2E2);
}
