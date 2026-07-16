import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/cart.dart';
import '../../../core/models/user_info.dart';
import '../../../core/services/api_service.dart';
import '../../../../main.dart';

class CheckoutPage extends StatefulWidget {
  final Cart cart;
  final VoidCallback onOrderSuccess;

  const CheckoutPage({
    super.key,
    required this.cart,
    required this.onOrderSuccess,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  String _deliveryMethod = 'Home'; // 'Home' or 'Store'
  String _paymentMethod = 'PayAtStore'; // 'PayAtStore' or 'PayOS'
  
  // Voucher variables
  final _voucherController = TextEditingController();
  Map<String, dynamic>? _appliedVoucher;
  bool _isValidatingVoucher = false;
  String? _voucherError;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = await ApiService.getSavedUser();
    if (user != null && mounted) {
      setState(() {
        _nameController.text = user.fullName;
        _phoneController.text = user.phone;
        _addressController.text = user.address;
      });
    }
  }

  // Calculate items total based on salePrice if available, otherwise regular price
  double get _totalAmount {
    double sum = 0.0;
    for (final item in widget.cart.items) {
      final priceToUse = item.salePrice > 0 ? item.salePrice : item.price;
      sum += priceToUse * item.quantity;
    }
    return sum;
  }

  double get _discountAmount {
    if (_appliedVoucher == null) return 0.0;
    
    final minOrder = _appliedVoucher!['minOrderAmount']?.toDouble() ?? 0.0;
    if (_totalAmount < minOrder) return 0.0;

    final discountType = _appliedVoucher!['discountType'] as String;
    final discountVal = _appliedVoucher!['discountValue']?.toDouble() ?? 0.0;

    if (discountType == 'Percentage') {
      double pctDiscount = (_totalAmount * discountVal) / 100;
      final maxDiscount = _appliedVoucher!['maxDiscount']?.toDouble() ?? 0.0;
      if (maxDiscount > 0 && pctDiscount > maxDiscount) {
        pctDiscount = maxDiscount;
      }
      return pctDiscount;
    } else {
      return discountVal;
    }
  }

  double get _finalAmount {
    final finalVal = _totalAmount - _discountAmount;
    return finalVal < 0 ? 0.0 : finalVal;
  }

  Future<void> _applyVoucher() async {
    final code = _voucherController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingVoucher = true;
      _voucherError = null;
    });

    final voucher = await ApiService.getVoucherByCode(code);
    
    if (!mounted) return;

    setState(() {
      _isValidatingVoucher = false;
      if (voucher != null) {
        final minOrder = voucher['minOrderAmount']?.toDouble() ?? 0.0;
        if (_totalAmount < minOrder) {
          _voucherError = 'Đơn hàng tối thiểu ${_formatCurrency(minOrder)} để áp dụng mã này';
          _appliedVoucher = null;
        } else {
          _appliedVoucher = voucher;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Áp dụng mã giảm giá thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        _voucherError = 'Mã giảm giá không hợp lệ hoặc đã hết hạn';
        _appliedVoucher = null;
      }
    });
  }

  void _removeVoucher() {
    setState(() {
      _appliedVoucher = null;
      _voucherController.clear();
      _voucherError = null;
    });
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final shippingAddress = _deliveryMethod == 'Store' 
          ? 'Nhận tại cửa hàng' 
          : _addressController.text.trim();

      final order = await ApiService.createOrder(
        receiverName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        shippingAddress: shippingAddress,
        note: _noteController.text.trim(),
        paymentMethod: _paymentMethod,
        voucherCode: _appliedVoucher != null ? _appliedVoucher!['code'] as String : null,
      );

      if (!mounted) return;

      if (order != null) {
        final orderId = order['id'] as String;

        // Clear cart globally
        widget.onOrderSuccess();

        if (_paymentMethod == 'PayOS') {
          // Generate PayOS Link
          final checkoutUrl = await ApiService.createPaymentLink(orderId);
          if (!mounted) return;
          if (checkoutUrl != null) {
            final uri = Uri.parse(checkoutUrl);
            final canLaunch = await canLaunchUrl(uri);
            if (!mounted) return;
            if (canLaunch) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không thể mở liên kết thanh toán. Vui lòng thanh toán sau.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tạo liên kết thanh toán PayOS thất bại. Hãy kiểm tra lại sau.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }

        if (!mounted) return;
        // Show Success Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Đặt hàng thành công'),
              ],
            ),
            content: Text(
              _paymentMethod == 'PayOS' 
                  ? 'Đơn hàng của bạn đã được khởi tạo. Hệ thống đã mở trình duyệt để thanh toán online.' 
                  : 'Đơn hàng đã đặt thành công! Cửa hàng sẽ liên hệ xác nhận sớm nhất.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // pop dialog
                  Navigator.of(context).pop(); // pop checkout page
                },
                child: const Text('ĐỒNG Ý', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đặt hàng thất bại. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';
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
          'Thanh toán & Đặt hàng',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Customer Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin khách nhận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Tên người nhận',
                          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên người nhận';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại',
                          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFEF4444)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Delivery Method
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hình thức nhận hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Giao tận nơi',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              selected: _deliveryMethod == 'Home',
                              onSelected: (val) {
                                if (val) setState(() => _deliveryMethod = 'Home');
                              },
                              selectedColor: const Color(0xFFEF4444).withOpacity(0.1),
                              checkmarkColor: const Color(0xFFEF4444),
                              labelStyle: TextStyle(
                                color: _deliveryMethod == 'Home'
                                    ? const Color(0xFFEF4444)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ChoiceChip(
                              label: const SizedBox(
                                width: double.infinity,
                                child: Text(
                                  'Nhận tại tiệm',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              selected: _deliveryMethod == 'Store',
                              onSelected: (val) {
                                if (val) setState(() => _deliveryMethod = 'Store');
                              },
                              selectedColor: const Color(0xFFEF4444).withOpacity(0.1),
                              checkmarkColor: const Color(0xFFEF4444),
                              labelStyle: TextStyle(
                                color: _deliveryMethod == 'Store'
                                    ? const Color(0xFFEF4444)
                                    : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                            ),
                          ),
                        ],
                      ),
                      if (_deliveryMethod == 'Home') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Địa chỉ nhận hàng',
                            labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFEF4444)),
                            ),
                          ),
                          validator: (value) {
                            if (_deliveryMethod == 'Home' && (value == null || value.trim().isEmpty)) {
                              return 'Vui lòng nhập địa chỉ nhận hàng';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Payment Method
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phương thức thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RadioListTile<String>(
                        title: const Text('Thanh toán khi nhận hàng / tại shop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Thanh toán bằng tiền mặt hoặc quét QR tĩnh lúc nhận máy.', style: TextStyle(fontSize: 12)),
                        value: 'PayAtStore',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMethod = val);
                        },
                      ),
                      const Divider(),
                      RadioListTile<String>(
                        title: const Text('Thanh toán Online (PayOS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Quét mã QR thanh toán nhanh qua thẻ ATM, Visa, MasterCard.', style: TextStyle(fontSize: 12)),
                        value: 'PayOS',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFEF4444),
                        onChanged: (val) {
                          if (val != null) setState(() => _paymentMethod = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Order Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: TextFormField(
                    controller: _noteController,
                    maxLines: 2,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú đơn hàng (tuỳ chọn)',
                      labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. Voucher code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã giảm giá / Voucher',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _voucherController,
                              style: TextStyle(color: theme.colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Nhập mã giảm giá...',
                                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onPressed: _isValidatingVoucher ? null : _applyVoucher,
                            child: _isValidatingVoucher
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                  )
                                : const Text('Áp dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      if (_voucherError != null) ...[
                        const SizedBox(height: 8),
                        Text(_voucherError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ],
                      if (_appliedVoucher != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đã áp dụng mã: ${_appliedVoucher!['code']}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                onPressed: _removeVoucher,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Billing Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đơn hàng của bạn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cart Items list preview
                      ...widget.cart.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: item.productImage.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(item.productImage, fit: BoxFit.contain),
                                      )
                                    : const Icon(Icons.phone_iphone, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.storage} | ${item.color}  x${item.quantity}',
                                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatCurrency((item.salePrice > 0 ? item.salePrice : item.price) * item.quantity),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tạm tính:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                          Text(_formatCurrency(_totalAmount), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phí vận chuyển:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                          Text('Miễn phí', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Giảm giá:', style: TextStyle(color: Colors.green, fontSize: 14)),
                            Text('- ${_formatCurrency(_discountAmount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tổng cộng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(_formatCurrency(_finalAmount), style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800, fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    onPressed: _isSubmitting ? null : _submitOrder,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white)),
                          )
                        : const Text(
                            'ĐẶT HÀNG NGAY',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
