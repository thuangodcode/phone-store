import 'package:flutter/material.dart';

class DockNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const DockNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Limit width on large screens for premium look
    final double dockWidth = screenWidth > 500 ? 460 : screenWidth * 0.90;

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.home_rounded, 'label': 'Trang chủ'},
      {'icon': Icons.shopping_cart_rounded, 'label': 'Giỏ hàng'},
      {'icon': Icons.search_rounded, 'label': 'Tìm kiếm'},
      {'icon': Icons.favorite_rounded, 'label': 'Yêu thích'},
      {'icon': Icons.person_rounded, 'label': 'Tài khoản'}, // Will render avatar style like mockup
    ];

    return Container(
      width: dockWidth,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.85), // Dark gray 900 with glassmorphism opacity
        borderRadius: BorderRadius.circular(36), // Pill-shaped
        border: Border.all(
          color: Colors.white.withOpacity(0.08), // Sleek subtle border
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 8), // Elegant dropdown shadow
          ),
          // Glow effect under active tab handled dynamically or static ambient glow
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.06), // Red soft ambient glow
            blurRadius: 30,
            spreadRadius: 8,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final isSelected = currentIndex == index;
          final item = items[index];

          // Special style for profile tab to match the horse avatar mockup
          final isProfile = index == 4;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.08) // active background box like mockup
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16), // Rounded square for active state
                    border: isSelected
                        ? Border.all(color: Colors.white.withOpacity(0.05), width: 1)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFEF4444).withOpacity(0.12), // Glowing active tab shadow
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: isProfile
                      ? _buildProfileTab(isSelected)
                      : AnimatedScale(
                          scale: isSelected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? const Color(0xFFEF4444) // Active brand red
                                : const Color(0xFF9CA3AF), // Inactive gray-400
                            size: isSelected ? 26 : 24,
                          ),
                        ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileTab(bool isSelected) {
    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFEF4444) // Active: brand red border
                : Colors.white.withOpacity(0.6), // Inactive: white border like mockup
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            color: const Color(0xFF374151), // Inner placeholder color
            child: const Icon(
              Icons.person,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
