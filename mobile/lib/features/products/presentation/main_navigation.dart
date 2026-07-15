import 'package:flutter/material.dart';
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
    final totalAmount = _cart?.totalAmount ?? 0.0;

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
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cartItems.length,
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
                              '${(totalAmount / 1000000).toStringAsFixed(1)} Tr đ',
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
                              '${(totalAmount / 1000000).toStringAsFixed(1)} Tr đ',
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tính năng đặt hàng đang được xử lý!'),
                                  backgroundColor: Color(0xFFEF4444),
                                ),
                              );
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phone_iphone,
              color: Color(0xFFEF4444),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.color.isNotEmpty || item.storage.isNotEmpty)
                  Text(
                    '${item.storage} | ${item.color}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  '${(item.price / 1000000).toStringAsFixed(1)} Tr đ',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildQtyBtn(
                Icons.remove,
                onTap: () => _updateQuantity(item.productId, item.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildQtyBtn(
                Icons.add,
                onTap: () => _updateQuantity(item.productId, item.quantity + 1),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                onPressed: () => _removeItem(item.productId),
              ),
            ],
          ),
        ],
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
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _searchResults.length,
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
    final discount = product.price > product.salePrice && product.salePrice > 0
        ? (((product.price - product.salePrice) / product.price) * 100).round()
        : 0;

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
          // Product Image placeholder / icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              product.brandName.toLowerCase().contains('apple') || product.name.toLowerCase().contains('iphone')
                  ? Icons.phone_iphone
                  : Icons.phone_android,
              color: const Color(0xFFEF4444),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.brandName,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${((product.salePrice > 0 ? product.salePrice : product.price) / 1000000).toStringAsFixed(1)} Tr đ',
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (discount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${(product.price / 1000000).toStringAsFixed(1)} Tr',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          decoration: TextDecoration.lineThrough,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF374151),
            size: 14,
          ),
        ],
      ),
    ));
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
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildWishlistItemWidget(item);
              },
            ),
    );
  }

  Widget _buildWishlistItemWidget(WishlistItem item) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phone_iphone,
              color: Color(0xFFEF4444),
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      item.inStock ? Icons.check_circle_outline : Icons.remove_circle_outline,
                      color: item.inStock ? Colors.green : Colors.red,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.inStock ? 'Còn hàng' : 'Hết hàng',
                      style: TextStyle(
                        color: item.inStock ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(item.price / 1000000).toStringAsFixed(1)} Tr đ',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.favorite,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            onPressed: () => _removeFromWishlist(item.productId),
          ),
        ],
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
    final String displayAvatar = _currentUser?.avatar ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: [
            const SizedBox(height: 24),
            // User Info Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEF4444),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB),
                      backgroundImage: displayAvatar.isNotEmpty ? NetworkImage(displayAvatar) : null,
                      child: displayAvatar.isEmpty
                          ? Icon(Icons.person, size: 48, color: isDark ? Colors.white : const Color(0xFF4B5563))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Menu list
            _buildMenuItem(
              Icons.history_rounded,
              'Lịch sử mua hàng',
              'Đơn hàng, Hóa đơn thanh toán',
            ),
            _buildMenuItem(
              Icons.discount_outlined,
              'Kho Voucher của tôi',
              'Ưu đãi & giảm giá độc quyền',
            ),
            _buildMenuItem(
              Icons.chat_bubble_outline_rounded,
              'Lịch sử chat hỗ trợ',
              'SignalR & Trợ lý AI logs',
            ),
            _buildMenuItem(
              Icons.dark_mode_outlined,
              'Chế độ giao diện tối',
              'Chuyển đổi giao diện Sáng / Tối',
              trailing: Switch(
                value: isDark,
                activeColor: const Color(0xFFEF4444),
                onChanged: (value) {
                  themeManager.toggleTheme(value);
                  setState(() {});
                },
              ),
            ),
            _buildMenuItem(
              Icons.security_outlined,
              'Bảo mật tài khoản',
              'Thay đổi mật khẩu, xác thực',
            ),
            _buildMenuItem(
              Icons.location_on_outlined,
              'Sổ địa chỉ nhận hàng',
              'Quản lý thông tin giao hàng',
            ),
            const Divider(color: Color(0xFF374151), height: 32),
            _buildMenuItem(
              Icons.logout_rounded,
              'Đăng xuất tài khoản',
              'Thoát khỏi phiên hoạt động',
              isDestructive: true,
              onTap: _handleLogout,
            ),
            const SizedBox(height: 120), // Bottom padding for float dock
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    bool isDestructive = false,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: trailing == null ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? const Color(0xFFEF4444).withOpacity(0.1)
                          : (isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                      size: 20,
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
                            color: isDestructive
                                ? const Color(0xFFEF4444)
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing ?? Icon(
                    Icons.arrow_forward_ios,
                    color: isDark ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
