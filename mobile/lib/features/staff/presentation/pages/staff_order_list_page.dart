import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../main.dart';

class StaffOrderListPage extends StatefulWidget {
  const StaffOrderListPage({super.key});

  @override
  State<StaffOrderListPage> createState() => _StaffOrderListPageState();
}

class _StaffOrderListPageState extends State<StaffOrderListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusKeys = ['ALL', 'Pending', 'Confirmed', 'Shipping', 'Delivered', 'Cancelled'];
  final List<String> _statusLabels = ['Tất cả', 'Chờ duyệt', 'Đã xác nhận', 'Đang giao', 'Đã giao', 'Đã hủy'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusKeys.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return;
    _filterOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final orders = await ApiService.getAllOrders();
      if (mounted) {
        setState(() {
          _allOrders = orders;
          _isLoading = false;
        });
        _filterOrders();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải đơn hàng: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _filterOrders() {
    final selectedStatus = _statusKeys[_tabController.index];
    setState(() {
      _filteredOrders = _allOrders.where((order) {
        final String orderId = order['id'] ?? '';
        final String customerName = (order['customerName'] ?? 'Khách hàng').toString().toLowerCase();
        final String shippingAddress = (order['shippingAddress'] ?? '').toString().toLowerCase();
        final String status = order['status'] ?? '';
        
        final matchesSearch = orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            customerName.contains(_searchQuery.toLowerCase()) ||
            shippingAddress.contains(_searchQuery.toLowerCase());
            
        if (selectedStatus == 'ALL') {
          return matchesSearch;
        } else {
          return matchesSearch && status == selectedStatus;
        }
      }).toList();
      
      // Sắp xếp đơn hàng mới nhất lên đầu
      _filteredOrders.sort((a, b) {
        final DateTime tA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final DateTime tB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return tB.compareTo(tA);
      });
    });
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

  void _showOrderDetailBottomSheet(String orderId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _OrderDetailBottomSheet(
          orderId: orderId,
          onOrderUpdated: _loadOrders,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Quản Lý Đơn Hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Thanh tìm kiếm
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 13),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _filterOrders();
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm theo mã đơn hoặc tên khách hàng...',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey, size: 16),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                                _filterOrders();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              // Các Tab trạng thái
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFFEF4444),
                labelColor: const Color(0xFFEF4444),
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black87,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: _statusLabels.map((label) => Tab(text: label)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadOrders,
              color: const Color(0xFFEF4444),
              child: _filteredOrders.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('Không tìm thấy đơn hàng nào.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
                      itemCount: _filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = _filteredOrders[index];
                        final String id = order['id'] ?? '';
                        final String customerName = order['customerName'] ?? 'Khách hàng';
                        final double amount = (order['finalAmount'] as num?)?.toDouble() ?? 0.0;
                        final String status = order['status'] ?? 'Pending';
                        final String paymentStatus = order['paymentStatus'] ?? 'Unpaid';
                        final DateTime createdAt = DateTime.tryParse(order['createdAt'] ?? '') ?? DateTime.now();

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

                        Color payColor = paymentStatus == 'Paid' ? Colors.green : Colors.red;
                        String payText = paymentStatus == 'Paid' ? 'Đã thanh toán' : 'Chưa thanh toán';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _showOrderDetailBottomSheet(id),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Mã: #${id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase()}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      Text(
                                        '${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24, color: Color(0x1F808080)),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Khách hàng: $customerName',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.payments_outlined, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            _formatCurrency(amount),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: payColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              payText,
                                              style: TextStyle(color: payColor, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: statusColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
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
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

// Widget BottomSheet hiển thị chi tiết đơn hàng & cập nhật trạng thái cho Staff
class _OrderDetailBottomSheet extends StatefulWidget {
  final String orderId;
  final VoidCallback onOrderUpdated;

  const _OrderDetailBottomSheet({
    required this.orderId,
    required this.onOrderUpdated,
  });

  @override
  State<_OrderDetailBottomSheet> createState() => _OrderDetailBottomSheetState();
}

class _OrderDetailBottomSheetState extends State<_OrderDetailBottomSheet> {
  bool _isLoading = true;
  Map<String, dynamic>? _order;
  bool _isSavingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final detail = await ApiService.getOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isSavingStatus = true;
    });
    try {
      final res = await ApiService.updateOrderStatus(widget.orderId, newStatus);
      if (res['success'] == true) {
        widget.onOrderUpdated();
        _loadOrderDetail(); // Tải lại chi tiết để xem audit logs
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật trạng thái đơn thành công!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Thất bại'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingStatus = false;
        });
      }
    }
  }

  Future<void> _updatePaymentStatus(String newPaymentStatus) async {
    setState(() {
      _isSavingStatus = true;
    });
    try {
      final res = await ApiService.updateOrderPaymentStatus(widget.orderId, newPaymentStatus);
      if (res['success'] == true) {
        widget.onOrderUpdated();
        _loadOrderDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật trạng thái thanh toán thành công!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Thất bại'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingStatus = false;
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

    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
          ),
        ),
      );
    }

    if (_order == null) return const SizedBox.shrink();

    final String id = _order!['id'] ?? '';
    final String status = _order!['status'] ?? 'Pending';
    final String paymentStatus = _order!['paymentStatus'] ?? 'Unpaid';
    final double amount = (_order!['finalAmount'] as num?)?.toDouble() ?? 0.0;
    final double originalAmount = (_order!['originalAmount'] as num?)?.toDouble() ?? 0.0;
    final double discountAmount = (_order!['discountAmount'] as num?)?.toDouble() ?? 0.0;
    
    final items = _order!['items'] as List<dynamic>? ?? [];
    final address = _order!['shippingAddress'];
    final logs = _order!['auditLogs'] as List<dynamic>? ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          // Drag handle indicator
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiết đơn: #${id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Trạng thái hành động nhanh (Duyệt đơn)
                  _buildActionPanel(status, paymentStatus),
                  const SizedBox(height: 20),

                  // 2. Thông tin khách hàng & giao hàng
                  const Text('THÔNG TIN GIAO HÀNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    theme,
                    isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(Icons.person_outline_rounded, 'Người nhận: ${_order!['customerName'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.phone_iphone_rounded, 'Số điện thoại: ${_order!['customerPhone'] ?? _order!['phoneNumber'] ?? 'N/A'}'),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ: ${_order!['shippingAddress'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Sản phẩm trong đơn hàng
                  const Text('DANH SÁCH SẢN PHẨM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    theme,
                    isDark,
                    child: Column(
                      children: items.map((item) {
                        final String name = item['productName'] ?? 'Sản phẩm';
                        final double price = (item['price'] as num?)?.toDouble() ?? 0.0;
                        final int quantity = item['quantity'] ?? 1;
                        final String img = item['productImage'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              img.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(img, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.phone_android)),
                                    )
                                  : const Icon(Icons.phone_android, size: 44),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 2),
                                    Text('Số lượng: $quantity', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(_formatCurrency(price * quantity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Tổng kết tiền thanh toán
                  _buildInfoCard(
                    theme,
                    isDark,
                    child: Column(
                      children: [
                        _buildAmountRow('Tạm tính:', originalAmount),
                        const SizedBox(height: 6),
                        _buildAmountRow('Giảm giá voucher:', -discountAmount, textColor: Colors.green),
                        const Divider(height: 20, color: Color(0x1F808080)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng thanh toán:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEF4444))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Nhật ký thay đổi (Audit logs)
                  const Text('NHẬT KÝ THAY ĐỔI (AUDIT LOG)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  _buildAuditLogsSection(logs, theme, isDark),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme, bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Widget _buildAmountRow(String label, double val, {Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(_formatCurrency(val), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor)),
      ],
    );
  }

  Widget _buildActionPanel(String status, String paymentStatus) {
    // Panel cập nhật trạng thái đơn cho Staff
    final isPending = status == 'Pending';
    final isConfirmed = status == 'Confirmed';
    final isShipping = status == 'Shipping';
    final isUnpaid = paymentStatus == 'Unpaid';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HÀNH ĐỘNG CỦA NHÂN VIÊN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444))),
          const SizedBox(height: 12),
          if (_isSavingStatus)
            const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (isPending)
                  ElevatedButton(
                    onPressed: () => _updateStatus('Confirmed'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Xác nhận đơn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (isConfirmed)
                  ElevatedButton(
                    onPressed: () => _updateStatus('Shipping'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Giao cho shipper', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (isShipping)
                  ElevatedButton(
                    onPressed: () => _updateStatus('Delivered'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Hoàn thành giao', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (isPending || isConfirmed)
                  OutlinedButton(
                    onPressed: () => _updateStatus('Cancelled'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Hủy đơn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                if (isUnpaid && status != 'Cancelled')
                  ElevatedButton(
                    onPressed: () => _updatePaymentStatus('Paid'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Xác nhận Đã trả tiền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsSection(List<dynamic> logs, ThemeData theme, bool isDark) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text('Chưa có lịch sử chỉnh sửa.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: logs.map((log) {
          final String user = log['changedBy'] ?? 'Hệ thống';
          final String action = log['action'] ?? '';
          final String note = log['note'] ?? '';
          final DateTime timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                          children: [
                            TextSpan(text: '$user ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: action),
                          ],
                        ),
                      ),
                      if (note.isNotEmpty)
                        Text('Lý do: $note', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      Text('${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
