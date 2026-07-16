import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../../../main.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/models/user_info.dart';
import '../../auth/presentation/login_page.dart';

// Import các trang của Staff
import 'pages/staff_dashboard_page.dart';
import 'pages/staff_order_list_page.dart';
import 'pages/staff_chat_list_page.dart';

class StaffNavigation extends StatefulWidget {
  const StaffNavigation({super.key});

  @override
  State<StaffNavigation> createState() => _StaffNavigationState();
}

class _StaffNavigationState extends State<StaffNavigation> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const StaffDashboardPage(),
      const StaffOrderListPage(),
      const StaffChatListPage(),
      const StaffSettingsTab(),
    ];

    // Kết nối SignalR Chat Hub cho Staff ngay khi vào app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      chatService.connect().then((_) {
        chatService.joinStaff(); // Tham gia group của Staff
      });
    });
  }

  Widget _buildStaffDockNavBar(bool isDark) {
    final double screenWidth = MediaQuery.of(context).size.width;
    // Giới hạn chiều rộng trên màn hình rộng cho thiết kế cao cấp
    final double dockWidth = screenWidth > 500 ? 400 : screenWidth * 0.90;

    final List<Map<String, dynamic>> items = [
      {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded, 'label': 'Tổng quan'},
      {'icon': Icons.receipt_long_outlined, 'activeIcon': Icons.receipt_long_rounded, 'label': 'Đơn hàng'},
      {'icon': Icons.chat_bubble_outline_rounded, 'activeIcon': Icons.chat_bubble_rounded, 'label': 'Hỗ trợ'},
      {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Hồ sơ'},
    ];

    return Container(
      width: dockWidth,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF111827).withOpacity(0.85)
            : Colors.white.withOpacity(0.9),
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
            offset: const Offset(0, 8),
          ),
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
          final isSelected = _currentIndex == index;
          final item = items[index];
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
                            isSelected ? item['activeIcon'] : item['icon'],
                            color: isSelected
                                ? const Color(0xFFEF4444)
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
                ? const Color(0xFFEF4444)
                : (isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.4)),
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
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Khu vực nội dung các trang
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // Dock Navigation Bar nằm lơ lửng ở dưới
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _buildStaffDockNavBar(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget tab cài đặt nhanh cho Staff
class StaffSettingsTab extends StatefulWidget {
  const StaffSettingsTab({super.key});

  @override
  State<StaffSettingsTab> createState() => _StaffSettingsTabState();
}

class _StaffSettingsTabState extends State<StaffSettingsTab> {
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
      Provider.of<ChatService>(context, listen: false).disconnect();
      await Provider.of<AuthProvider>(context, listen: false).logout();
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
        } catch (e) {}
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
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message'] ?? ''),
                                  backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                                ),
                              );

                              if (result['success'] == true) {
                                _loadUserProfile();
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
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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

    final String displayName = _currentUser?.fullName ?? 'Nhân viên';
    final String displayEmail = _currentUser?.email ?? 'staff@phonestore.com';
    final String displayPhone = _currentUser?.phone ?? 'Chưa thiết lập';
    final String displayAddress = _currentUser?.address ?? 'Chưa thiết lập';
    final String displayAvatar = _currentUser?.avatar ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
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
                              const Color(0xFF1E1B4B),
                              const Color(0xFF311042),
                              const Color(0xFF581C87),
                            ]
                          : [
                              const Color(0xFFFCA5A5),
                              const Color(0xFFEF4444),
                              const Color(0xFFB91C1C),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.withOpacity(0.4), width: 1),
                            ),
                            child: const Text(
                              'NHÂN VIÊN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                            label: 'Địa chỉ của tôi',
                            value: displayAddress,
                            isMultiLine: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.dark_mode_outlined, color: Colors.amber, size: 18),
                            ),
                            title: const Text(
                              'Giao diện tối (Dark Mode)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            trailing: Switch(
                              value: isDark,
                              activeColor: const Color(0xFFEF4444),
                              onChanged: (value) {
                                themeManager.toggleTheme(value);
                              },
                            ),
                          ),
                          const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                          _buildMenuItem(
                            context,
                            icon: Icons.info_outline_rounded,
                            title: 'Phiên bản ứng dụng',
                            subtitle: '1.0.0+1',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 120),
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
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
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
            ],
          ),
        ),
      ),
    );
  }
}
