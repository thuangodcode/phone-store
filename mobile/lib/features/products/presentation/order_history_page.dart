import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';
import '../../../../main.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final ordersData = await ApiService.getMyOrders();
      if (mounted) {
        setState(() {
          _orders = ordersData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Không thể tải lịch sử đơn hàng';
          _isLoading = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber;
      case 'Confirmed':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Chờ xác nhận';
      case 'Confirmed':
        return 'Đã xác nhận';
      case 'Shipped':
        return 'Đang giao';
      case 'Delivered':
        return 'Đã giao';
      case 'Cancelled':
        return 'Đã huỷ';
      default:
        return 'Không rõ';
    }
  }

  Future<void> _checkPayment(int orderCode) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang kiểm tra trạng thái thanh toán từ PayOS...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final result = await ApiService.checkPaymentStatus(orderCode);
      if (!mounted) return;

      if (result != null) {
        final success = result['success'] == true;
        final data = result['data'];
        
        if (success && data != null && data['paid'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đơn hàng đã được thanh toán thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrders(); // Tải lại đơn hàng để cập nhật trạng thái
        } else {
          final payosStatus = data != null ? data['payosStatus'] : 'Không rõ';
          final message = result['message'] ?? 'Chưa thanh toán hoặc lỗi.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Trạng thái PayOS: $payosStatus - $message'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể lấy thông tin thanh toán từ hệ thống.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kiểm tra thanh toán: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final borderColor = isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Lịch sử mua hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: _loadOrders,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                        ),
                        onPressed: _loadOrders,
                        child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 80,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Bạn chưa có đơn hàng nào.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tiếp tục mua sắm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final items = order['items'] as List<dynamic>? ?? [];
                        final finalAmount = (order['finalAmount'] as num?)?.toDouble() ?? 0.0;
                        final orderCode = order['orderCode'] as int? ?? 0;
                        final status = order['status'] as String? ?? 'Pending';
                        final paymentStatus = order['paymentStatus'] as String? ?? 'Unpaid';
                        final paymentMethod = order['paymentMethod'] as String? ?? 'PayAtStore';
                        final createdAtStr = order['createdAt'] as String? ?? '';
                        
                        String displayDate = '';
                        try {
                          if (createdAtStr.isNotEmpty) {
                            final parsedDate = DateTime.parse(createdAtStr).toLocal();
                            displayDate = '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
                          }
                        } catch (_) {}

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order Header
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1F2937).withOpacity(0.3) : const Color(0xFFF9FAFB),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Mã đơn: #$orderCode',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _getStatusText(status),
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          displayDate,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: paymentStatus == 'Paid' ? Colors.green : Colors.red,
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                paymentStatus == 'Paid' ? 'Đã thanh toán' : 'Chưa thanh toán',
                                                style: TextStyle(
                                                  color: paymentStatus == 'Paid' ? Colors.green : Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            if (paymentStatus != 'Paid' && paymentMethod == 'PayOS') ...[
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _checkPayment(orderCode),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEF4444).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Kiểm tra',
                                                    style: TextStyle(
                                                      color: Color(0xFFEF4444),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Items List
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: items.length,
                                  separatorBuilder: (context, index) => const Divider(height: 24),
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    final productName = item['productName'] as String? ?? '';
                                    final productImage = item['productImage'] as String? ?? '';
                                    final storage = item['storage'] as String? ?? '';
                                    final color = item['color'] as String? ?? '';
                                    final quantity = item['quantity'] as int? ?? 1;
                                    final price = (item['price'] as num?)?.toDouble() ?? 0.0;

                                    return Row(
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: productImage.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(productImage, fit: BoxFit.contain),
                                                )
                                              : const Icon(Icons.phone_iphone, color: Colors.grey),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                productName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Dung lượng: $storage | Màu: $color',
                                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Số lượng: x$quantity',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatCurrency(price),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),

                              const Divider(height: 1),

                              // Order Footer
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Người nhận: ${order['receiverName'] ?? order['userName'] ?? ''} - ${order['phone'] ?? ''}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Địa chỉ: ${order['shippingAddress'] ?? ''}',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    if (order['note'] != null && (order['note'] as String).trim().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ghi chú: ${order['note']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Hình thức: ${paymentMethod == 'PayOS' ? 'Thanh toán Online (PayOS)' : 'Thanh toán khi nhận hàng'}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        Text.rich(
                                          TextSpan(
                                            text: 'Tổng tiền: ',
                                            style: const TextStyle(fontSize: 13, color: Colors.grey),
                                            children: [
                                              TextSpan(
                                                text: _formatCurrency(finalAmount),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFEF4444),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
