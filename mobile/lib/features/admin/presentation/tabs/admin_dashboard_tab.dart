import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../main.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await ApiService.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AdminDashboardTab: Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: const [
              SizedBox(height: 24),
              ShimmerChart(),
              SizedBox(height: 24),
              ShimmerChart(),
              SizedBox(height: 24),
              ShimmerCardList(itemCount: 3),
            ],
          ),
        ),
      );
    }

    if (_stats == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Không thể tải dữ liệu thống kê'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadDashboardData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final revenue = _stats!['revenue'] ?? {};
    final orders = _stats!['orders'] ?? {};
    final topProducts = _stats!['topProducts'] as List<dynamic>? ?? [];

    final totalRevenue = _parseDouble(revenue['totalRevenue']);
    final monthlyRevenue = _parseDouble(revenue['monthlyRevenue']);
    final dailyRevenue = _parseDouble(revenue['dailyRevenue']);

    final totalOrders = _parseInt(orders['totalOrders']);
    final pendingOrders = _parseInt(orders['pendingOrders']);
    final confirmedOrders = _parseInt(orders['confirmedOrders']);
    final shippingOrders = _parseInt(orders['shippingOrders']);
    final deliveredOrders = _parseInt(orders['deliveredOrders']);
    final cancelledOrders = _parseInt(orders['cancelledOrders']);

    final totalCustomers = _parseInt(_stats!['totalCustomers']);
    final totalProducts = _parseInt(_stats!['totalProducts']);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tổng Quan Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurface),
            onPressed: _loadDashboardData,
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: Colors.purple,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Thẻ thống kê tổng quát (Grid)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    title: 'Khách hàng',
                    value: totalCustomers.toString(),
                    icon: Icons.people_outline_rounded,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    title: 'Sản phẩm',
                    value: totalProducts.toString(),
                    icon: Icons.phone_android_rounded,
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    title: 'Tổng Đơn Hàng',
                    value: totalOrders.toString(),
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    title: 'Hôm nay',
                    value: currencyFormat.format(dailyRevenue),
                    icon: Icons.monetization_on_outlined,
                    color: Colors.red,
                    isCompactValue: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Biểu đồ Doanh thu (Bar Chart)
              _buildSectionTitle('BÁO CÁO DOANH THU'),
              const SizedBox(height: 8),
              _buildRevenueChart(dailyRevenue, monthlyRevenue, totalRevenue),

              const SizedBox(height: 28),

              // Biểu đồ đơn hàng (Pie Chart)
              _buildSectionTitle('PHÂN BỐ TRẠNG THÁI ĐƠN HÀNG'),
              const SizedBox(height: 8),
              _buildOrdersPieChart(
                pending: pendingOrders,
                confirmed: confirmedOrders,
                shipping: shippingOrders,
                delivered: deliveredOrders,
                cancelled: cancelledOrders,
              ),

              const SizedBox(height: 28),

              // Sản phẩm bán chạy nhất
              _buildSectionTitle('SẢN PHẨM BÁN CHẠY NHẤT'),
              const SizedBox(height: 8),
              _buildTopProductsList(topProducts),
              const SizedBox(height: 120), // Tránh đệm bị Dock che khuất
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isCompactValue = false,
  }) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompactValue ? 15 : 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(double daily, double monthly, double total) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    double maxVal = monthly;
    if (daily > maxVal) maxVal = daily;
    if (maxVal == 0) maxVal = 1000000;

    return Container(
      height: 260,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Báo cáo doanh thu thời gian (₫)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: const Color(0xFF1E293B),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label = '';
                      if (group.x == 0) label = 'Ngày';
                      if (group.x == 1) label = 'Tháng';
                      return BarTooltipItem(
                        '$label: ${currencyFormat.format(rod.toY)}',
                        const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11);
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Hôm nay', style: style);
                            break;
                          case 1:
                            text = const Text('Tháng này', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(axisSide: meta.axisSide, child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox();
                        String text = '';
                        if (value >= 1000000) {
                          text = '${(value / 1000000).toStringAsFixed(1)}M';
                        } else if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(0)}K';
                        } else {
                          text = value.toStringAsFixed(0);
                        }
                        return Text(
                          text,
                          style: const TextStyle(color: Colors.grey, fontSize: 9),
                          textAlign: TextAlign.right,
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: daily,
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.red],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      )
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: monthly,
                        gradient: const LinearGradient(
                          colors: [Colors.purple, Colors.deepPurpleAccent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Tổng Doanh Thu Lũy Kế: ${currencyFormat.format(total)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.purple),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrdersPieChart({
    required int pending,
    required int confirmed,
    required int shipping,
    required int delivered,
    required int cancelled,
  }) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    final total = pending + confirmed + shipping + delivered + cancelled;
    if (total == 0) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text('Chưa có dữ liệu đơn hàng.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: [
                  if (pending > 0)
                    PieChartSectionData(
                      color: Colors.orange,
                      value: pending.toDouble(),
                      title: '$pending',
                      radius: 26,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (confirmed > 0)
                    PieChartSectionData(
                      color: Colors.blue,
                      value: confirmed.toDouble(),
                      title: '$confirmed',
                      radius: 26,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (shipping > 0)
                    PieChartSectionData(
                      color: Colors.teal,
                      value: shipping.toDouble(),
                      title: '$shipping',
                      radius: 26,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (delivered > 0)
                    PieChartSectionData(
                      color: Colors.green,
                      value: delivered.toDouble(),
                      title: '$delivered',
                      radius: 26,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (cancelled > 0)
                    PieChartSectionData(
                      color: Colors.red,
                      value: cancelled.toDouble(),
                      title: '$cancelled',
                      radius: 26,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Chú thích
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildIndicator(color: Colors.orange, text: 'Chờ duyệt ($pending)'),
              _buildIndicator(color: Colors.blue, text: 'Đã duyệt ($confirmed)'),
              _buildIndicator(color: Colors.teal, text: 'Đang giao ($shipping)'),
              _buildIndicator(color: Colors.green, text: 'Đã giao ($delivered)'),
              _buildIndicator(color: Colors.red, text: 'Hủy ($cancelled)'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIndicator({required Color color, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTopProductsList(List<dynamic> products) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    if (products.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: Text('Chưa có sản phẩm bán chạy.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length > 5 ? 5 : products.length,
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 72, color: const Color(0x1F808080)),
          itemBuilder: (context, index) {
            final prod = products[index];
            final String name = prod['productName'] ?? 'Sản phẩm';
            final String image = prod['productImage'] ?? '';
            final int sold = _parseInt(prod['totalSold']);
            final double revenue = _parseDouble(prod['totalRevenue']);

            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 44,
                  color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                  child: image.isNotEmpty
                      ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.phone_android))
                      : const Icon(Icons.phone_android),
                ),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('Đã bán: $sold', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              trailing: Text(
                currencyFormat.format(revenue),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.purple),
              ),
            );
          },
        ),
      ),
    );
  }
}
