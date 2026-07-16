import 'package:flutter/material.dart';
import '../../../../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cài đặt hệ thống',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Section 1: Giao diện
            _buildSectionTitle(context, 'GIAO DIỆN & HIỂN THỊ'),
            const SizedBox(height: 8),
            _buildSettingCard(
              context,
              children: [
                _buildSettingItem(
                  context,
                  icon: Icons.dark_mode_outlined,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Chế độ giao diện tối',
                  subtitle: 'Tối ưu hóa hiển thị vào ban đêm',
                  trailing: Switch(
                    value: isDark,
                    activeColor: const Color(0xFFEF4444),
                    activeTrackColor: const Color(0xFFEF4444).withOpacity(0.3),
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
                    onChanged: (value) async {
                      await themeManager.toggleTheme(value);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 2: Ngôn ngữ & Vùng
            _buildSectionTitle(context, 'NGÔN NGỮ & QUỐC GIA'),
            const SizedBox(height: 8),
            _buildSettingCard(
              context,
              children: [
                _buildSettingItem(
                  context,
                  icon: Icons.language_rounded,
                  iconColor: Colors.blue,
                  title: 'Ngôn ngữ ứng dụng',
                  subtitle: 'Lựa chọn ngôn ngữ hiển thị',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Tiếng Việt',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                        size: 14,
                      ),
                    ],
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ứng dụng hiện tại chỉ hỗ trợ Tiếng Việt'),
                        backgroundColor: Color(0xFFEF4444),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 3: Thông tin ứng dụng
            _buildSectionTitle(context, 'THÔNG TIN ỨNG DỤNG'),
            const SizedBox(height: 8),
            _buildSettingCard(
              context,
              children: [
                _buildSettingItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.green,
                  title: 'Phiên bản ứng dụng',
                  subtitle: 'Phiên bản hiện tại của phần mềm',
                  trailing: Text(
                    'v1.0.0 (Release)',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                _buildSettingItem(
                  context,
                  icon: Icons.shield_outlined,
                  iconColor: Colors.orange,
                  title: 'Chính sách bảo mật',
                  subtitle: 'Quyền riêng tư & bảo mật thông tin',
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 14,
                  ),
                  onTap: () {
                    _showInfoDialog(
                      context,
                      title: 'Chính sách bảo mật',
                      content: 'Chúng tôi cam kết bảo mật tuyệt đối mọi thông tin cá nhân của khách hàng. Mọi giao dịch và dữ liệu cá nhân đều được mã hóa và bảo vệ theo các tiêu chuẩn bảo mật tiên tiến nhất.',
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, color: Color(0x1F808080)),
                _buildSettingItem(
                  context,
                  icon: Icons.description_outlined,
                  iconColor: Colors.purple,
                  title: 'Điều khoản sử dụng',
                  subtitle: 'Các quy định khi sử dụng dịch vụ',
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 14,
                  ),
                  onTap: () {
                    _showInfoDialog(
                      context,
                      title: 'Điều khoản sử dụng',
                      content: 'Khi sử dụng ứng dụng PhoneStore, bạn đồng ý tuân thủ các quy định về mua hàng, thanh toán và đổi trả sản phẩm của chúng tôi. Chúng tôi giữ quyền cập nhật điều khoản bất kỳ lúc nào để cải thiện chất lượng dịch vụ.',
                    );
                  },
                ),
              ],
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

  Widget _buildSettingCard(BuildContext context, {required List<Widget> children}) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              // Text Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing Widget
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, {required String title, required String content}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        content: Text(
          content,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Đã hiểu',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
