import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../core/services/auth_provider.dart';
import '../../../../main.dart';
import 'staff_chat_detail_page.dart';

class StaffChatListPage extends StatefulWidget {
  const StaffChatListPage({super.key});

  @override
  State<StaffChatListPage> createState() => _StaffChatListPageState();
}

class _StaffChatListPageState extends State<StaffChatListPage> {
  bool _isLoading = true;
  List<dynamic> _sessions = [];
  StreamSubscription? _newMessageSubscription;
  StreamSubscription? _staffAssignedSubscription;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _setupSignalRListeners();
  }

  @override
  void dispose() {
    _newMessageSubscription?.cancel();
    _staffAssignedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final sessions = await ApiService.getChatSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải phòng chat: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _setupSignalRListeners() {
    final chatService = Provider.of<ChatService>(context, listen: false);

    // Lắng nghe sự kiện tin nhắn mới -> tự động tải lại danh sách session
    _newMessageSubscription = chatService.newMessageStream.listen((_) {
      print('StaffChatListPage: Received NewMessage event, reloading sessions');
      _loadSessions();
    });

    // Lắng nghe sự kiện phân công Staff -> cập nhật trạng thái session trong list cục bộ
    _staffAssignedSubscription = chatService.staffAssignedStream.listen((updatedSession) {
      print('StaffChatListPage: Received StaffAssigned event');
      if (mounted) {
        setState(() {
          _sessions = _sessions.map((s) {
            if (s['id'] == updatedSession['id']) {
              return updatedSession;
            }
            return s;
          }).toList();
        });
      }
    });
  }

  Future<void> _assignStaff(String sessionId) async {
    try {
      final result = await ApiService.assignStaffToSession(sessionId);
      if (result != null) {
        _loadSessions();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;
    final currentUser = Provider.of<AuthProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kênh Hỗ Trợ Khách Hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSessions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSessions,
              color: const Color(0xFFEF4444),
              child: _sessions.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            const Text('Hiện tại không có cuộc trò chuyện nào cần hỗ trợ.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final String id = session['id'] ?? '';
                        final String customerName = session['customerName'] ?? 'Khách hàng';
                        final String? staffId = session['staffId'];
                        final String? staffName = session['staffName'];
                        final String updatedAtStr = session['updatedAt'] ?? '';
                        final DateTime updatedAt = DateTime.tryParse(updatedAtStr) ?? DateTime.now();

                        final bool isAssignedToMe = staffId == currentUser?.id;
                        final bool isUnassigned = staffId == null || staffId.isEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StaffChatDetailPage(
                                    sessionId: id,
                                    customerName: customerName,
                                    staffId: staffId,
                                    staffName: staffName,
                                  ),
                                ),
                              ).then((_) => _loadSessions());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        customerName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text(
                                        '${updatedAt.hour}:${updatedAt.minute.toString().padLeft(2, '0')} ${updatedAt.day}/${updatedAt.month}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Trạng thái hỗ trợ
                                      Expanded(
                                        child: isUnassigned
                                            ? const Text(
                                                'Chưa có người hỗ trợ',
                                                style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
                                              )
                                            : Text(
                                                isAssignedToMe ? 'Đang được bạn hỗ trợ' : 'Hỗ trợ bởi: $staffName',
                                                style: TextStyle(
                                                  color: isAssignedToMe ? Colors.green : Colors.grey,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                      ),
                                      // Nút hành động nhanh
                                      if (isUnassigned)
                                        ElevatedButton(
                                          onPressed: () => _assignStaff(id),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFEF4444),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Nhận hỗ trợ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
