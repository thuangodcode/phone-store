import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../main.dart';

class StaffDashboardPage extends StatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  State<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends State<StaffDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải dữ liệu thống kê. Vui lòng thử lại.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double value) {
    final int intValue = value.toInt();
    final String valueStr = intValue.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = valueStr.length - 1; i >= 0; i--) {
      buffer.write(valueStr[i]);
      count++;
      if (count == 3 && i != 0) {
        buffer.write('.');
        count = 0;
      }
    }
    return '${buffer.toString().split('').reversed.join('')} đ';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bảng Vận Hành', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadDashboardData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Tải lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  color: const Color(0xFFEF4444),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Chào nhân viên
                        const Text(
                          'Chào ngày làm việc mới,',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Chúc bạn một ngày hiệu quả!',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),

                        // Bento Grid thống kê
                        _buildBentoStatsGrid(isDark),
                        const SizedBox(height: 28),

                        // Đơn hàng cần xử lý gấp
                        _buildRecentOrdersHeader(theme),
                        const SizedBox(height: 12),
                        _buildRecentOrdersList(theme, isDark),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildBentoStatsGrid(bool isDark) {
    // Phân tích stats
    final revenue = _stats?['revenue'];
    final orders = _stats?['orders'];
    final double dailyRevenue = (revenue?['dailyRevenue'] ?? 0).toDouble();
    final double monthlyRevenue = (revenue?['monthlyRevenue'] ?? 0).toDouble();

    final int pending = orders?['pendingOrders'] ?? 0;
    final int shipping = orders?['shippingOrders'] ?? 0;
    final int confirmed = orders?['confirmedOrders'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        // Doanh thu ngày
        _buildStatCard(
          title: 'Doanh thu hôm nay',
          value: _formatCurrency(dailyRevenue),
          icon: Icons.monetization_on_rounded,
          color: Colors.green,
          isDark: isDark,
        ),
        // Đơn chờ duyệt
        _buildStatCard(
          title: 'Đơn chờ duyệt',
          value: '$pending đơn',
          icon: Icons.pending_actions_rounded,
          color: Colors.orange,
          isDark: isDark,
          badgeCount: pending,
        ),
        // Đang giao
        _buildStatCard(
          title: 'Đang giao hàng',
          value: '$shipping đơn',
          icon: Icons.local_shipping_rounded,
          color: Colors.blue,
          isDark: isDark,
        ),
        // Doanh thu tháng
        _buildStatCard(
          title: 'Doanh thu tháng này',
          value: _formatCurrency(monthlyRevenue),
          icon: Icons.calendar_month_rounded,
          color: Colors.purple,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    int badgeCount = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
          if (badgeCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ĐƠN HÀNG GẦN ĐÂY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.grey,
          ),
        ),
        TextButton(
          onPressed: () {
            // Có thể định hướng sang tab Order
          },
          child: const Text('Xem tất cả', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildRecentOrdersList(ThemeData theme, bool isDark) {
    final List<dynamic> recentOrders = _stats?['recentOrders'] ?? [];

    if (recentOrders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          ),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_outlined, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text('Không có đơn hàng gần đây', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentOrders.length > 5 ? 5 : recentOrders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = recentOrders[index];
        final String orderId = order['orderId'] ?? '';
        final String customerName = order['customerName'] ?? 'Khách hàng';
        final double amount = (order['finalAmount'] as num?)?.toDouble() ?? 0.0;
        final String status = order['status'] ?? 'Pending';
        final String createdAtStr = order['createdAt'] ?? '';

        Color statusColor = Colors.orange;
        String statusText = 'Chờ duyệt';
        if (status == 'Confirmed') {
          statusColor = Colors.indigo;
          statusText = 'Đã xác nhận';
        } else if (status == 'Shipping') {
          statusColor = Colors.blue;
          statusText = 'Đang giao';
        } else if (status == 'Delivered') {
          statusColor = Colors.green;
          statusText = 'Đã giao';
        } else if (status == 'Cancelled') {
          statusColor = Colors.red;
          statusText = 'Đã hủy';
        }

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
            ),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn hàng: #${orderId.length > 6 ? orderId.substring(orderId.length - 6).toUpperCase() : orderId.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Khách: $customerName',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFEF4444)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
