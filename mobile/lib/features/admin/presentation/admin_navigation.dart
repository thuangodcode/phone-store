import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../../../main.dart';
import '../../../../core/services/auth_provider.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/admin_users_tab.dart';
import '../../staff/presentation/pages/staff_order_list_page.dart';
import 'tabs/admin_profile_tab.dart';

class AdminNavigation extends StatefulWidget {
  const AdminNavigation({super.key});

  @override
  State<AdminNavigation> createState() => _AdminNavigationState();
}

class _AdminNavigationState extends State<AdminNavigation> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const AdminDashboardTab(),
      const AdminUsersTab(),
      const StaffOrderListPage(),
      const AdminProfileTab(),
    ];
  }

  Widget _buildAdminDockNavBar(bool isDark) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double dockWidth = screenWidth > 500 ? 400 : screenWidth * 0.90;

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded, 'label': 'Thống kê'},
      {'icon': Icons.people_outline_rounded, 'activeIcon': Icons.people_rounded, 'label': 'Người dùng'},
      {'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long_rounded, 'label': 'Đơn hàng'},
      {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Cá nhân'},
    ];

    return Container(
      width: dockWidth,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111827).withOpacity(0.85)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.purple.withOpacity(isDark ? 0.08 : 0.05),
            blurRadius: 30,
            spreadRadius: 8,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = _currentIndex == index;
          final isProfile = index == 3;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentIndex = index;
                });
              },
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
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            width: 1,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.12),
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
                            isSelected ? item['activeIcon'] : item['icon'],
                            color: isSelected
                                ? Colors.purple
                                : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
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

  Widget _buildProfileTab(bool isSelected, bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

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
                ? Colors.purple
                : (isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.4)),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            child: user?.avatar != null && user!.avatar.isNotEmpty
                ? (user.avatar.startsWith('data:image')
                    ? Image.memory(base64Decode(user.avatar.split(',').last), fit: BoxFit.cover)
                    : Image.network(user.avatar, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 16)))
                : Icon(
                    Icons.person,
                    size: 16,
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Nội dung tab
          Positioned.fill(
            child: _pages[_currentIndex],
          ),
          // Dock Tab Bar lơ lửng ở dưới cùng
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: _buildAdminDockNavBar(isDark),
            ),
          ),
        ],
      ),
    );
  }
}
