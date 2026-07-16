import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../customer_chat_page.dart';

class FloatingChatButtons extends StatelessWidget {
  const FloatingChatButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Button 1: AI Assistant Chat (Gradient Premium Purple/Blue)
          _buildChatButton(
            context: context,
            icon: Icons.auto_awesome,
            tooltip: 'Trợ lý AI',
            badgeText: 'AI',
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)], // Purple-500 to Blue-500
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: () {
              _showChatDialog(
                context: context,
                title: 'Trợ lý mua sắm AI',
                icon: Icons.auto_awesome,
                accentColor: const Color(0xFF8B5CF6),
                welcomeMessage: 'Xin chào! Tôi là Trợ lý AI của PhoneStore. Bạn cần so sánh sản phẩm hay tìm kiếm cấu hình như thế nào?',
                isAi: true,
              );
            },
          ),
          const SizedBox(height: 12),
          // Button 2: Live Staff Chat (Realtime SignalR - Red)
          _buildChatButton(
            context: context,
            icon: Icons.chat_bubble_outline,
            tooltip: 'Nhân viên tư vấn',
            badgeText: 'Live',
            color: const Color(0xFFEF4444), // Primary red brand color
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerChatPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    String? badgeText,
    Color? color,
    Gradient? gradient,
  }) {
    return Stack(
      alignment: Alignment.topRight,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gradient == null ? color : null,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: (color ?? const Color(0xFF8B5CF6)).withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Tooltip(
                message: tooltip,
                child: Center(
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Mini status badge overlay
        if (badgeText != null)
          Positioned(
            top: -4,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: badgeText == 'Live'
                    ? const Color(0xFF22C55E) // Green for Live status
                    : const Color(0xFFEC4899), // Pink/Magenta for AI status
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF030712), // Border matches Background Dark Gray 950
                  width: 1.5,
                ),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showChatDialog({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color accentColor,
    required String welcomeMessage,
    required bool isAi,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ChatBottomSheetContent(
          title: title,
          icon: icon,
          accentColor: accentColor,
          welcomeMessage: welcomeMessage,
          isAi: isAi,
        );
      },
    );
  }
}

// Widget Stateful để xử lý nội dung trò chuyện
class ChatBottomSheetContent extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String welcomeMessage;
  final bool isAi;

  const ChatBottomSheetContent({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.welcomeMessage,
    required this.isAi,
  });

  @override
  State<ChatBottomSheetContent> createState() => _ChatBottomSheetContentState();
}

class _ChatBottomSheetContentState extends State<ChatBottomSheetContent> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message from agent
    _messages.add({
      'sender': 'bot',
      'text': widget.welcomeMessage,
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
      });
      _isTyping = true;
    });
    _scrollToBottom();

    if (widget.isAi) {
      // Call Real Gemini AI Agent Endpoint
      final result = await ApiService.sendAIChatMessage(text, _sessionId);
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': result['response'] ?? 'Không nhận được câu trả lời từ AI.',
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } else {
      // Simulate real consultant response after a short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'bot',
            'text': 'Cám ơn bạn đã gửi tin nhắn. Yêu cầu của bạn đang được kết nối tới nhân viên tư vấn. Vui lòng chờ trong giây lát!',
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Slate-900 (Dark Mode)
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFF1E293B), // Slate-800 border
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.accentColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Color(0xFFF9FAFB),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Đang hoạt động',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Show Typing Indicator
                  return _buildTypingIndicator();
                }

                final msg = _messages[index];
                final isUser = msg['sender'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? widget.accentColor : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFFE5E7EB),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input Area
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF334155),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Color(0xFFF9FAFB), fontSize: 14),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn hỗ trợ...',
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: widget.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.isAi ? 'Trợ lý AI' : 'Tư vấn viên'} đang nhập...',
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
