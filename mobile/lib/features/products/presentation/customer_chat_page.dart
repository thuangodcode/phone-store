import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../main.dart';

class CustomerChatPage extends StatefulWidget {
  const CustomerChatPage({super.key});

  @override
  State<CustomerChatPage> createState() => _CustomerChatPageState();
}

class _CustomerChatPageState extends State<CustomerChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  String? _sessionId;
  String? _staffName;
  String? _staffId;
  List<dynamic> _messages = [];

  StreamSubscription? _chatMessageSubscription;
  StreamSubscription? _staffAssignedSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _chatMessageSubscription?.cancel();
    _staffAssignedSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Kết nối SignalR Hub trước
      final chatService = Provider.of<ChatService>(context, listen: false);
      if (!chatService.isConnected) {
        await chatService.connect();
      }

      // 2. Lấy active chat session của Customer từ Backend
      final session = await ApiService.getActiveChatSession();
      if (session != null && mounted) {
        setState(() {
          _sessionId = session['id'];
          _staffId = session['staffId'];
          _staffName = session['staffName'];
        });

        // 3. Tải tin nhắn cũ
        await _loadMessages();

        // 4. Thiết lập lắng nghe SignalR
        _setupSignalR();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể khởi tạo phiên chat. Vui lòng thử lại!'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khởi tạo chat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_sessionId == null) return;
    try {
      final messages = await ApiService.getChatMessages(_sessionId!);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('CustomerChatPage: Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupSignalR() {
    if (_sessionId == null) return;
    final chatService = Provider.of<ChatService>(context, listen: false);

    // Tham gia phòng chat
    chatService.joinSession(_sessionId!);

    // Lắng nghe tin nhắn mới realtime
    _chatMessageSubscription = chatService.messageStream.listen((message) {
      if (message['sessionId'] == _sessionId) {
        print('CustomerChatPage: Received message realtime');
        if (mounted) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
        }
      }
    });

    // Lắng nghe xem có Staff nào nhận hỗ trợ không
    _staffAssignedSubscription = chatService.staffAssignedStream.listen((session) {
      if (session['id'] == _sessionId) {
        print('CustomerChatPage: Staff assigned update');
        if (mounted) {
          setState(() {
            _staffId = session['staffId'];
            _staffName = session['staffName'];
          });
        }
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sessionId == null) return;

    _messageController.clear();

    try {
      final sentMsg = await ApiService.sendChatMessage(_sessionId!, text);
      if (sentMsg != null) {
        // Backend tự đẩy qua SignalR tới cả 2 phía nên ở đây không cần add thủ công để tránh trùng lặp.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e'), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    final hasStaff = _staffId != null && _staffId!.isNotEmpty;
    final staffDisplayName = hasStaff ? _staffName ?? 'Nhân viên hỗ trợ' : 'Đang chờ tư vấn viên...';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: hasStaff
                  ? const Color(0xFF22C55E).withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
              child: Icon(
                hasStaff ? Icons.support_agent_rounded : Icons.hourglass_empty_rounded,
                color: hasStaff ? const Color(0xFF22C55E) : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffDisplayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: hasStaff ? const Color(0xFF22C55E) : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        hasStaff ? 'Đang hỗ trợ bạn' : 'Hệ thống đang kết nối',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              ),
            )
          : Column(
              children: [
                // Danh sách tin nhắn
                Expanded(
                  child: Container(
                    color: isDark ? const Color(0xFF111827) : const Color(0xFFF9FAFB),
                    child: _messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMyMessage = msg['senderId'] == currentUser?.id;
                              final senderName = msg['senderName'] ?? 'Người dùng';
                              final content = msg['content'] ?? '';
                              final timestampStr = msg['timestamp'] ?? '';

                              return _buildChatBubble(isMyMessage, senderName, content, timestampStr);
                            },
                          ),
                  ),
                ),

                // Thanh soạn thảo tin nhắn
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 10,
                    bottom: MediaQuery.of(context).padding.bottom + 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? const Color(0xFF374151) : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            maxLines: 4,
                            minLines: 1,
                            decoration: const InputDecoration(
                              hintText: 'Nhập tin nhắn để chat với nhân viên...',
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: Color(0xFFEF4444),
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trò Chuyện Trực Tuyến',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn đang kết nối trực tiếp đến phòng hỗ trợ. Hãy gửi tin nhắn để nhân viên của chúng tôi trợ giúp bạn nhé!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(bool isMe, String senderName, String content, String timestamp) {
    final isDark = themeManager.isDarkMode;

    String displayTime = '';
    try {
      if (timestamp.isNotEmpty) {
        final parsed = DateTime.parse(timestamp).toLocal();
        displayTime = '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
      }
    } catch (_) {}

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 6.0, bottom: 4.0),
                child: Text(
                  senderName,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFFEF4444)
                    : (isDark ? const Color(0xFF1F2937) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                content,
                style: TextStyle(
                  color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            if (displayTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, right: 6.0, left: 6.0),
                child: Text(
                  displayTime,
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
