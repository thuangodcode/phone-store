import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/core/services/api_service.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  Timer? _timer;
  List<dynamic> _promotions = [];
  bool _isLoading = true;

  // Dữ liệu fallback mặc định nếu API không có bài đăng nào hoặc lỗi
  final List<Map<String, dynamic>> _fallbackBanners = [
    {
      'title': 'Galaxy S24 Ultra',
      'subtitle': 'Quyền năng Galaxy AI',
      'promo': 'Giảm ngay 5.000.000đ + Thu cũ đổi mới',
      'colors': [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      'tag': 'Hot Deal',
      'imageUrl': '',
      'imageIcon': Icons.star_purple500_outlined,
    },
    {
      'title': 'iPhone 15 Pro Max',
      'subtitle': 'Titan tự nhiên siêu bền bỉ',
      'promo': 'Trả góp 0% lãi suất + Tặng bảo hành VIP 2 năm',
      'colors': [const Color(0xFF881337), const Color(0xFF4C0519)],
      'tag': 'Bán Chạy',
      'imageUrl': '',
      'imageIcon': Icons.phone_iphone,
    },
    {
      'title': 'Đại Tiệc Xiaomi',
      'subtitle': 'Xiaomi 14 Series đỉnh cao Leica',
      'promo': 'Ưu đãi lên đến 30% + Tặng Tai nghe Buds 5',
      'colors': [const Color(0xFF7C2D12), const Color(0xFF431407)],
      'tag': 'Ưu Đãi lớn',
      'imageUrl': '',
      'imageIcon': Icons.camera_enhance,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    try {
      final articles = await ApiService.getArticles();
      if (mounted) {
        setState(() {
          _promotions = articles;
          _isLoading = false;
        });
        _startAutoPlay();
      }
    } catch (e) {
      print('Load promotions error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _startAutoPlay();
      }
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    final itemCount = _promotions.isNotEmpty ? _promotions.length : _fallbackBanners.length;
    if (itemCount <= 1) return;
    
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final carouselHeight = screenHeight * 0.22;

    final isPromoEmpty = _promotions.isEmpty;
    final itemCount = isPromoEmpty ? _fallbackBanners.length : _promotions.length;

    if (_isLoading) {
      return SizedBox(
        height: carouselHeight,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page ?? 0) - index;
                    value = (1 - (value.abs() * 0.08)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * carouselHeight,
                      width: double.infinity,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Background (Image from URL or Gradient)
                        ..._buildBackground(isPromoEmpty ? _fallbackBanners[index] : _promotions[index]),

                        // Content Overlay
                        _buildContent(isPromoEmpty ? _fallbackBanners[index] : _promotions[index], isPromoEmpty),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        // Indicators
        if (itemCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(itemCount, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 5,
                width: isActive ? 18 : 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: isActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF374151),
                ),
              );
            }),
          ),
      ],
    );
  }

  List<Widget> _buildBackground(dynamic bannerData) {
    final String? imageUrl = bannerData is Map ? bannerData['imageUrl'] : bannerData['imageUrl'];
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return [
        Positioned.fill(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),
        ),
        // Dark Overlay for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Colors.black.withOpacity(0.9),
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
        ),
      ];
    } else {
      // Fallback Gradient
      final List<Color> colors = bannerData is Map && bannerData.containsKey('colors')
          ? List<Color>.from(bannerData['colors'])
          : [const Color(0xFF1E293B), const Color(0xFF0F172A)];

      return [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
        ),
        // Decorative glowing circle behind
        Positioned(
          right: -50,
          top: -50,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
            ),
          ),
        ),
      ];
    }
  }

  Widget _buildContent(dynamic bannerData, bool isFallback) {
    String tag = 'HOT';
    String title = '';
    String subtitle = '';
    String promo = '';
    IconData icon = Icons.discount_outlined;

    if (isFallback) {
      tag = bannerData['tag'] ?? 'HOT';
      title = bannerData['title'] ?? '';
      subtitle = bannerData['subtitle'] ?? '';
      promo = bannerData['promo'] ?? '';
      icon = bannerData['imageIcon'] as IconData? ?? Icons.star_purple500_outlined;
    } else {
      tag = 'TIN HOT';
      title = bannerData['title'] ?? '';
      
      // Author and date as subtitle
      final author = bannerData['authorName'] ?? 'Hệ thống';
      final dateStr = bannerData['createdAt'] ?? '';
      String formattedDate = '';
      try {
        if (dateStr.isNotEmpty) {
          final parsedDate = DateTime.parse(dateStr).toLocal();
          formattedDate = '${parsedDate.day}/${parsedDate.month}';
        }
      } catch (_) {}
      subtitle = 'Đăng bởi $author ${formattedDate.isNotEmpty ? '• $formattedDate' : ''}';

      // Trim content for promo line
      final String content = bannerData['content'] ?? '';
      promo = content.split('\n')[0]; // Lấy dòng đầu tiên
      if (promo.length > 60) {
        promo = '${promo.substring(0, 57)}...';
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      key: ValueKey(title),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF9FAFB),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  promo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFEAB308),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isFallback)
            Expanded(
              flex: 1,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white.withOpacity(0.8),
                    size: 32,
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}
