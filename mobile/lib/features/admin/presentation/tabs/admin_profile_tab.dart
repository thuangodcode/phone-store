import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../main.dart';
import '../../../auth/presentation/login_page.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(BuildContext context, StateSetter setStateDialog, Function(String) onImageBase64) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        onImageBase64(base64String);
        setStateDialog(() {});
      }
    } catch (e) {
      print('Pick Image Error: $e');
    }
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final user = authProvider.currentUser;
    final isDark = themeManager.isDarkMode;

    final nameController = TextEditingController(text: user?.fullName);
    final phoneController = TextEditingController(text: user?.phone);
    final addressController = TextEditingController(text: user?.address);
    String currentAvatar = user?.avatar ?? '';
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.edit_rounded, color: Colors.purple, size: 24),
                  SizedBox(width: 8),
                  Text('Sửa hồ sơ Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar Picker
                    GestureDetector(
                      onTap: () => _pickImage(context, setStateDialog, (b64) {
                        currentAvatar = b64;
                      }),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            backgroundImage: currentAvatar.isNotEmpty
                                ? (currentAvatar.startsWith('data:image')
                                    ? MemoryImage(base64Decode(currentAvatar.split(',').last))
                                    : NetworkImage(currentAvatar) as ImageProvider)
                                : null,
                            child: currentAvatar.isEmpty
                                ? Text(
                                    user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'A',
                                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.purple),
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Name input
                    TextField(
                      controller: nameController,
                      decoration: _buildInputDecoration('Họ và tên', Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    // Phone input
                    TextField(
                      controller: phoneController,
                      decoration: _buildInputDecoration('Số điện thoại', Icons.phone_android),
                    ),
                    const SizedBox(height: 16),
                    // Address input
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: _buildInputDecoration('Địa chỉ', Icons.location_on_outlined),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setStateDialog(() {
                            isSaving = true;
                          });
                          final success = await authProvider.updateProfile(
                            fullName: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            address: addressController.text.trim(),
                            avatar: currentAvatar,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cập nhật hồ sơ thành công!'), backgroundColor: Colors.green),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cập nhật hồ sơ thất bại.'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    final isDark = themeManager.isDarkMode;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.purple, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.purple, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeManager.isDarkMode ? const Color(0xFF111827) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Admin không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Đóng dialog
              authProvider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Gradient
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B21A8), Color(0xFF4C1D95)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  top: 50,
                  child: Column(
                    children: const [
                      Text(
                        'Hồ Sơ Admin',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quản lý cấu hình & cài đặt',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      )
                    ],
                  ),
                ),
                Positioned(
                  bottom: -45,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.purple.withOpacity(0.1),
                      backgroundImage: user?.avatar != null && user!.avatar.isNotEmpty
                          ? (user.avatar.startsWith('data:image')
                              ? MemoryImage(base64Decode(user.avatar.split(',').last))
                              : NetworkImage(user.avatar) as ImageProvider)
                          : null,
                      child: user?.avatar == null || user!.avatar.isEmpty
                          ? Text(
                              user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : 'A',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 55),
            Text(
              user?.fullName ?? 'Quản trị viên',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'admin@phonestore.com',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ADMINISTRATOR',
                style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
            ),
            const SizedBox(height: 24),

            // Profile info card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('THÔNG TIN CÁ NHÂN', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person_outline_rounded, 'Họ và tên', user?.fullName ?? ''),
                        const Divider(height: 1, indent: 48),
                        _buildInfoRow(Icons.phone_android_rounded, 'Số điện thoại', user?.phone ?? ''),
                        const Divider(height: 1, indent: 48),
                        _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', user?.address ?? ''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('CÀI ĐẶT ỨNG DỤNG', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dark_mode_outlined, color: Colors.amber),
                          title: const Text('Chế độ tối (Dark Mode)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          trailing: Switch(
                            value: isDark,
                            activeColor: Colors.purple,
                            onChanged: (val) {
                              themeManager.toggleTheme(val);
                            },
                          ),
                        ),
                        const Divider(height: 1, indent: 48),
                        ListTile(
                          onTap: () => _showEditProfileDialog(context, authProvider),
                          leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                          title: const Text('Chỉnh sửa thông tin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 18),
                        ),
                        const Divider(height: 1, indent: 48),
                        const ListTile(
                          leading: Icon(Icons.info_outline_rounded, color: Colors.grey),
                          title: Text('Phiên bản phần mềm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          trailing: Text('1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, authProvider),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                    label: const Text('Đăng xuất Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 120), // Tránh đệm bị Dock che khuất
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : 'Chưa cập nhật', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
