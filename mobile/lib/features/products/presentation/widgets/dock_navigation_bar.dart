import 'package:flutter/material.dart';
import '../../../../main.dart';

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
    return ListenableBuilder(
      listenable: themeManager,
      builder: (context, _) {
        final isDark = themeManager.isDarkMode;
        final theme = Theme.of(context);
        final double screenWidth = MediaQuery.of(context).size.width;
        // Limit width on large screens for premium look
        final double dockWidth = screenWidth > 500 ? 460 : screenWidth * 0.90;

        final List<Map<String, dynamic>> items = [
          {'icon': Icons.home_rounded, 'label': 'Trang chủ'},
          {'icon': Icons.shopping_cart_rounded, 'label': 'Giỏ hàng'},
          {'icon': Icons.search_rounded, 'label': 'Tìm kiếm'},
          {'icon': Icons.favorite_rounded, 'label': 'Yêu thích'},
          {'icon': Icons.person_rounded, 'label': 'Tài khoản'},
        ];

        return Container(
          width: dockWidth,
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF111827).withOpacity(0.85)
                : Colors.white.withOpacity(0.9), // Glassmorphism background depending on theme
            borderRadius: BorderRadius.circular(36), // Pill-shaped
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8), // Elegant dropdown shadow
              ),
              // Glow effect under active tab handled dynamically or static ambient glow
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(isDark ? 0.06 : 0.04),
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

              // Special style for profile tab
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
                            ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16), // Rounded square for active state
                        border: isSelected
                            ? Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                width: 1,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withOpacity(0.12),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isProfile
                          ? _buildProfileTab(isSelected, isDark)
                          : AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 250),
                              child: Icon(
                                item['icon'] as IconData,
                                color: isSelected
                                    ? const Color(0xFFEF4444) // Active brand red
                                    : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)), // Inactive color
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
      },
    );
  }

  Widget _buildProfileTab(bool isSelected, bool isDark) {
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
                : (isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.4)), // Inactive
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
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB), // Inner placeholder color
            child: Icon(
              Icons.person,
              size: 16,
              color: isDark ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }
}
