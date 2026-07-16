import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../main.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  bool _isLoading = true;
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];

  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'Tất cả';
  String _selectedStatus = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await ApiService.getUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AdminUsersTab: Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredUsers = _users.where((user) {
        final fullName = (user['fullName'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final phone = (user['phone'] ?? '').toString().toLowerCase();
        final role = (user['role'] ?? '').toString();
        final isActive = user['isActive'] == true;

        final matchesQuery = query.isEmpty ||
            fullName.contains(query) ||
            email.contains(query) ||
            phone.contains(query);

        final matchesRole = _selectedRole == 'Tất cả' || role == _selectedRole;

        final matchesStatus = _selectedStatus == 'Tất cả' ||
            (_selectedStatus == 'Hoạt động' && isActive) ||
            (_selectedStatus == 'Bị khóa' && !isActive);

        return matchesQuery && matchesRole && matchesStatus;
      }).toList();
    });
  }

  Future<void> _handleToggleStatus(dynamic user) async {
    final String userId = user['id'];
    final bool currentStatus = user['isActive'] == true;
    final String actionText = currentStatus ? 'khóa' : 'mở khóa';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: Text('Xác nhận $actionText', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn $actionText tài khoản ${user['fullName']}?', style: const TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              currentStatus ? 'Khóa tài khoản' : 'Mở khóa',
              style: TextStyle(
                color: currentStatus ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      final result = await ApiService.toggleUserStatus(userId);
      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã ${actionText} tài khoản thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi cập nhật trạng thái tài khoản.'), backgroundColor: Colors.red),
          );
        }
        _loadUsers();
      }
    }
  }

  Future<void> _handleDeleteUser(dynamic user) async {
    final String userId = user['id'];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        title: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn tài khoản ${user['fullName']}? Thao tác này không thể hoàn tác.', style: const TextStyle(color: Color(0xFF9CA3AF))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa tài khoản', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      final success = await ApiService.deleteUser(userId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa tài khoản thành công!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể xóa tài khoản. Vui lòng thử lại!'), backgroundColor: Colors.red),
          );
        }
        _loadUsers();
      }
    }
  }

  void _showCreateUserDialog() {
    final isDark = themeManager.isDarkMode;
    final formKey = GlobalKey<FormState>();

    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    String role = 'Staff';
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
                  Icon(Icons.person_add_alt_1_rounded, color: Colors.purple, size: 28),
                  SizedBox(width: 8),
                  Text('Tạo nhân viên mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      // Full Name
                      TextFormField(
                        controller: fullNameController,
                        decoration: _buildInputDecoration('Họ và tên', Icons.person_outline),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Nhập họ tên nhân viên' : null,
                      ),
                      const SizedBox(height: 16),
                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration('Email đăng nhập', Icons.email_outlined),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Nhập email';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Password
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: _buildInputDecoration('Mật khẩu', Icons.lock_outline),
                        validator: (value) => value == null || value.length < 6 ? 'Mật khẩu từ 6 ký tự trở lên' : null,
                      ),
                      const SizedBox(height: 16),
                      // Phone
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration('Số điện thoại', Icons.phone_android),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Nhập số điện thoại' : null,
                      ),
                      const SizedBox(height: 16),
                      // Address
                      TextFormField(
                        controller: addressController,
                        maxLines: 2,
                        decoration: _buildInputDecoration('Địa chỉ', Icons.location_on_outlined),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Nhập địa chỉ cư trú' : null,
                      ),
                      const SizedBox(height: 16),
                      // Role Selection (Staff / Admin)
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: _buildInputDecoration('Vai trò', Icons.admin_panel_settings_outlined),
                        dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                        items: ['Staff', 'Admin'].map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(r == 'Staff' ? 'Nhân viên (Staff)' : 'Quản trị viên (Admin)'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              role = val;
                            });
                          }
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
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setStateDialog(() {
                              isSaving = true;
                            });

                            final result = await ApiService.adminCreateUser({
                              'fullName': fullNameController.text.trim(),
                              'email': emailController.text.trim(),
                              'password': passwordController.text,
                              'phone': phoneController.text.trim(),
                              'address': addressController.text.trim(),
                              'role': role,
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              if (result != null && result['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tạo tài khoản mới thành công!'), backgroundColor: Colors.green),
                                );
                                _loadUsers();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result?['message'] ?? 'Lỗi tạo tài khoản'), backgroundColor: Colors.red),
                                );
                              }
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
                      : const Text('Tạo ngay', style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản Lý Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tìm kiếm và Lọc
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, email hoặc SĐT...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.purple),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: (val) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                            items: ['Tất cả', 'Customer', 'Staff', 'Admin'].map((r) {
                              return DropdownMenuItem<String>(
                                value: r,
                                child: Text(r == 'Tất cả' ? 'Tất cả Vai trò' : r, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedRole = val;
                                });
                                _applyFilters();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                            items: ['Tất cả', 'Hoạt động', 'Bị khóa'].map((s) {
                              return DropdownMenuItem<String>(
                                value: s,
                                child: Text(s == 'Tất cả' ? 'Tất cả Trạng thái' : s, style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedStatus = val;
                                });
                                _applyFilters();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Danh sách người dùng
          Expanded(
            child: _isLoading
                ? const ShimmerCardList(itemCount: 6, height: 90)
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.people_alt_outlined, color: Colors.grey, size: 48),
                            SizedBox(height: 12),
                            Text('Không tìm thấy tài khoản người dùng nào.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        color: Colors.purple,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final String name = user['fullName'] ?? 'Không tên';
                            final String email = user['email'] ?? 'Không email';
                            final String role = user['role'] ?? 'Customer';
                            final bool isActive = user['isActive'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(role).withOpacity(0.1),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: TextStyle(color: _getRoleColor(role), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildRoleBadge(role),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isActive ? Colors.green : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isActive ? 'Đang hoạt động' : 'Đang bị khóa',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isActive ? Colors.green : Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  onSelected: (action) {
                                    if (action == 'toggle') {
                                      _handleToggleStatus(user);
                                    } else if (action == 'delete') {
                                      _handleDeleteUser(user);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'toggle',
                                      child: Row(
                                        children: [
                                          Icon(
                                            isActive ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                                            color: isActive ? Colors.red : Colors.green,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(isActive ? 'Khóa tài khoản' : 'Mở khóa'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                          SizedBox(width: 8),
                                          Text('Xóa tài khoản', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: Colors.purple,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'staff':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Widget _buildRoleBadge(String role) {
    final color = _getRoleColor(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }
}
