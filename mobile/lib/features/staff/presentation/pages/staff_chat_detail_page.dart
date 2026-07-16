import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../core/models/product.dart';
import '../../../../main.dart';

class StaffChatDetailPage extends StatefulWidget {
  final String sessionId;
  final String customerName;
  final String? staffId;
  final String? staffName;

  const StaffChatDetailPage({
    super.key,
    required this.sessionId,
    required this.customerName,
    this.staffId,
    this.staffName,
  });

  @override
  State<StaffChatDetailPage> createState() => _StaffChatDetailPageState();
}

class _StaffChatDetailPageState extends State<StaffChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  List<dynamic> _messages = [];
  String? _currentStaffId;
  String? _currentStaffName;
  
  StreamSubscription? _chatMessageSubscription;
  StreamSubscription? _staffAssignedSubscription;

  final List<String> _quickReplies = [
    "Chào bạn, PhoneStore có thể giúp gì cho bạn hôm nay?",
    "Cảm ơn quý khách đã quan tâm đến sản phẩm của shop.",
    "Sản phẩm này hiện đang có sẵn, quý khách có muốn đặt hàng ngay không?",
    "Xin lỗi quý khách vì sự chậm trễ này, chúng tôi sẽ kiểm tra và phản hồi lại ngay.",
    "Cảm ơn quý khách, chúc quý khách một ngày tốt lành!"
  ];

  @override
  void initState() {
    super.initState();
    _currentStaffId = widget.staffId;
    _currentStaffName = widget.staffName;
    _loadMessages();
    _setupSignalR();
  }

  @override
  void dispose() {
    _chatMessageSubscription?.cancel();
    _staffAssignedSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final messages = await ApiService.getChatMessages(widget.sessionId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _setupSignalR() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    // Tham gia vào phòng chat cụ thể này
    chatService.joinSession(widget.sessionId);

    // Lắng nghe tin nhắn mới realtime
    _chatMessageSubscription = chatService.messageStream.listen((message) {
      if (message['sessionId'] == widget.sessionId) {
        print('StaffChatDetailPage: Received message realtime');
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      }
    });

    // Lắng nghe sự kiện staff được chỉ định
    _staffAssignedSubscription = chatService.staffAssignedStream.listen((session) {
      if (session['id'] == widget.sessionId) {
        print('StaffChatDetailPage: Received staff assigned update');
        if (mounted) {
          setState(() {
            _currentStaffId = session['staffId'];
            _currentStaffName = session['staffName'];
          });
        }
      }
    });
  }

  Future<void> _sendMessage({String? customContent}) async {
    final text = customContent ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (customContent == null) {
      _messageController.clear();
    }

    try {
      final sentMsg = await ApiService.sendChatMessage(widget.sessionId, text);
      if (sentMsg != null) {
        // API Backend tự đẩy tin nhắn qua Hub, nên chúng ta không cần thêm thủ công.
        // Tuy nhiên, nếu WebSocket chậm, chúng ta có thể tự add.
        // Backend render của chúng ta đã lo phần đồng bộ qua SignalR.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _assignStaff() async {
    try {
      final result = await ApiService.assignStaffToSession(widget.sessionId);
      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã nhận hỗ trợ cuộc trò chuyện này!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi nhận hỗ trợ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showQuickRepliesBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('Tin nhắn mẫu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _quickReplies.length,
                  itemBuilder: (context, index) {
                    final reply = _quickReplies[index];
                    return ListTile(
                      title: Text(reply, style: const TextStyle(fontSize: 14)),
                      onTap: () {
                        Navigator.pop(context);
                        _sendMessage(customContent: reply);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;
    final currentUser = Provider.of<AuthProvider>(context).currentUser;
    
    final bool isUnassigned = _currentStaffId == null || _currentStaffId!.isEmpty;
    final bool isAssignedToMe = _currentStaffId == currentUser?.id;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              isUnassigned
                  ? 'Chưa có người hỗ trợ'
                  : (isAssignedToMe ? 'Bạn đang hỗ trợ' : 'Nhân viên: $_currentStaffName'),
              style: TextStyle(
                fontSize: 11,
                color: isUnassigned
                    ? Colors.orange
                    : (isAssignedToMe ? Colors.green : Colors.grey),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0.5,
        actions: [
          if (isUnassigned)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Center(
                child: ElevatedButton(
                  onPressed: _assignStaff,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Nhận hỗ trợ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Vùng hiển thị tin nhắn
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text('Bắt đầu cuộc trò chuyện', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final String senderId = msg['senderId'] ?? '';
                          final String senderName = msg['senderName'] ?? 'Hệ thống';
                          final String senderRole = msg['senderRole'] ?? '';
                          final String content = msg['content'] ?? '';
                          final String timestampStr = msg['timestamp'] ?? '';
                          final DateTime time = DateTime.tryParse(timestampStr) ?? DateTime.now();

                          final bool isMe = senderId == currentUser?.id;
                          final bool isSystem = senderRole == 'System' || senderId == 'system';

                          return _buildMessageBubble(
                            content: content,
                            senderName: senderName,
                            senderRole: senderRole,
                            isMe: isMe,
                            isSystem: isSystem,
                            time: time,
                            isDark: isDark,
                            theme: theme,
                          );
                        },
                      ),
          ),
          
          // Vùng nhập tin nhắn
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Nút chọn tin nhắn mẫu
                  IconButton(
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.amber),
                    onPressed: _showQuickRepliesBottomSheet,
                    tooltip: 'Tin nhắn mẫu',
                  ),
                  
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Nút Gửi
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEF4444),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required String senderName,
    required String senderRole,
    required bool isMe,
    required bool isSystem,
    required DateTime time,
    required bool isDark,
    required ThemeData theme,
  }) {
    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final String timeStr = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    final bool isProduct = content.startsWith('[PRODUCT]:');
    final String productId = isProduct ? content.replaceFirst('[PRODUCT]:', '') : '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Tên người gửi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
            child: Text(
              '$senderName ($senderRole)',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
          
          // Bong bóng tin nhắn
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFFEF4444)
                      : (isDark ? const Color(0xFF1F2937) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 2),
                    bottomRight: Radius.circular(isMe ? 2 : 16),
                  ),
                  border: isMe
                      ? null
                      : Border.all(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isProduct
                    ? _buildProductPreview(productId, isMe, theme)
                    : Text(
                        content,
                        style: TextStyle(
                          color: isMe ? Colors.white : theme.colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
              ),
            ],
          ),
          
          // Giờ gửi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
            child: Text(
              timeStr,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPreview(String productId, bool isMe, ThemeData theme) {
    return FutureBuilder<Product?>(
      future: ApiService.getProductById(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 150,
            height: 50,
            child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey)),
          );
        }
        
        final product = snapshot.data;
        if (product == null) {
          return const Text('[Sản phẩm không tồn tại hoặc đã bị xóa]');
        }

        final double price = product.price.toDouble();
        final String image = product.images.isNotEmpty ? product.images[0] : '';

        return Container(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sản phẩm quan tâm:',
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(image, width: 40, height: 40, fit: BoxFit.cover),
                    )
                  else
                    const Icon(Icons.phone_android, size: 40),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isMe ? Colors.white : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${price.toInt().toString()} đ',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                        ),
                      ],
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
