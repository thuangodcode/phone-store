import 'dart:async';
import 'package:flutter/material.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Galaxy S24 Ultra',
      'subtitle': 'Quyền năng Galaxy AI',
      'promo': 'Giảm ngay 5.000.000đ + Thu cũ đổi mới',
      'colors': [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      'tag': 'Hot Deal',
      'imageIcon': Icons.star_purple500_outlined,
    },
    {
      'title': 'iPhone 15 Pro Max',
      'subtitle': 'Titan tự nhiên siêu bền bỉ',
      'promo': 'Trả góp 0% lãi suất + Tặng bảo hành VIP 2 năm',
      'colors': [const Color(0xFF881337), const Color(0xFF4C0519)], // Dark Red theme for premium feel
      'tag': 'Bán Chạy',
      'imageIcon': Icons.phone_iphone,
    },
    {
      'title': 'Đại Tiệc Xiaomi',
      'subtitle': 'Xiaomi 14 Series đỉnh cao Leica',
      'promo': 'Ưu đãi lên đến 30% + Tặng Tai nghe Buds 5',
      'colors': [const Color(0xFF7C2D12), const Color(0xFF431407)], // Dark Orange theme
      'tag': 'Ưu Đãi lớn',
      'imageIcon': Icons.camera_enhance,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
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
    // Height responsive based on screen size
    final screenHeight = MediaQuery.of(context).size.height;
    final carouselHeight = screenHeight * 0.22;

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
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
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
                    borderRadius: BorderRadius.circular(16), // --radius-2xl = 16px
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: banner['colors'],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4), // Standard elevation lg shadow
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
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
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16.0), // --space-4 = 16px
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
                                        color: const Color(0xFFEF4444).withOpacity(0.2), // --color-destructive / --color-red-500
                                        borderRadius: BorderRadius.circular(4), // --radius-default = 4px
                                        border: Border.all(
                                          color: const Color(0xFFEF4444).withOpacity(0.4),
                                        ),
                                      ),
                                      child: Text(
                                        banner['tag'].toString().toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFFFCA5A5), // Light Red
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8), // --space-2 = 8px
                                    Text(
                                      banner['title'],
                                      style: const TextStyle(
                                        color: Color(0xFFF9FAFB), // --color-gray-50
                                        fontSize: 20, // --font-heading
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      banner['subtitle'],
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF), // --color-gray-400
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      banner['promo'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFEAB308), // --color-warning = yellow-500
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                      banner['imageIcon'] as IconData,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 32,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 5,
              width: isActive ? 18 : 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isActive
                    ? const Color(0xFFEF4444) // Active: Primary Accent Red
                    : const Color(0xFF374151), // Inactive: Gray-700
              ),
            );
          }),
        ),
      ],
    );
  }
}
