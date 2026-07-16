import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../main.dart';

class AdminAITracesTab extends StatefulWidget {
  const AdminAITracesTab({super.key});

  @override
  State<AdminAITracesTab> createState() => _AdminAITracesTabState();
}

class _AdminAITracesTabState extends State<AdminAITracesTab> {
  bool _isLoading = true;
  List<dynamic> _traces = [];

  String? _expandedTraceId;
  int? _expandedEventIdx;

  @override
  void initState() {
    super.initState();
    _loadTraces();
  }

  Future<void> _loadTraces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final traces = await ApiService.getAITraces();
      if (mounted) {
        setState(() {
          _traces = traces;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('AdminAITracesTab: Error loading AI Traces: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatJSON(dynamic raw) {
    if (raw == null) return '';
    try {
      if (raw is String) {
        final parsed = jsonDecode(raw);
        return const JsonEncoder.withIndent('  ').convert(parsed);
      }
      return const JsonEncoder.withIndent('  ').convert(raw);
    } catch (_) {
      return raw.toString();
    }
  }

  String _formatEventSummary(dynamic raw) {
    if (raw == null) return 'Không có dữ liệu chi tiết.';
    try {
      final parsed = raw is String ? jsonDecode(raw) : raw;
      if (parsed is List) {
        return 'Mảng gồm ${parsed.length} phần tử';
      }
      if (parsed is Map) {
        final keys = parsed.keys.toList();
        if (keys.isEmpty) return 'Không có dữ liệu chi tiết.';
        final previewKeys = keys.take(3).join(', ');
        return 'Dữ liệu gồm các trường: $previewKeys${keys.length > 3 ? '...' : ''}';
      }
      final str = parsed.toString();
      return str.length > 100 ? '${str.substring(0, 100)}...' : str;
    } catch (_) {
      final str = raw.toString();
      return str.length > 100 ? '${str.substring(0, 100)}...' : str;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PROMPT_COMPILED':
        return Icons.terminal_rounded;
      case 'LLM_RESPONSE':
        return Icons.bolt_rounded;
      case 'TOOL_EXECUTION':
        return Icons.auto_awesome_mosaic_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  Color _getEventColor(String type) {
    switch (type.toUpperCase()) {
      case 'PROMPT_COMPILED':
        return Colors.blue;
      case 'LLM_RESPONSE':
        return Colors.purple;
      case 'TOOL_EXECUTION':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getEventTitle(String type) {
    switch (type.toUpperCase()) {
      case 'PROMPT_COMPILED':
        return 'Biên dịch lời gọi';
      case 'LLM_RESPONSE':
        return 'Phản hồi AI';
      case 'TOOL_EXECUTION':
        return 'Thực thi công cụ';
      default:
        return 'Sự kiện khác';
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Quản trị viên';
      case 'staff':
        return 'Nhân viên';
      case 'customer':
        return 'Khách hàng';
      default:
        return 'Khách vãng lai';
    }
  }

  String _truncateSessionId(String sessionId) {
    if (sessionId.length <= 16) return sessionId;
    return '${sessionId.substring(0, 8)}...${sessionId.substring(sessionId.length - 8)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lịch Sử Tương Tác AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.onSurface),
            onPressed: _loadTraces,
          )
        ],
      ),
      body: _isLoading
          ? const ShimmerCardList(itemCount: 6, height: 95)
          : _traces.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.history_toggle_off_rounded, color: Colors.grey, size: 48),
                      const SizedBox(height: 12),
                      Text('Không tìm thấy log tương tác AI nào.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTraces,
                  color: Colors.purple,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _traces.length,
                    itemBuilder: (context, index) {
                      final trace = _traces[index];
                      final String id = trace['id'] ?? '';
                      final String sessionId = trace['sessionId'] ?? '';
                      final String userRole = trace['userRole'] ?? '';
                      final String createdAtStr = trace['createdAt'] ?? '';
                      final events = trace['events'] as List<dynamic>? ?? [];

                      DateTime? createdAt;
                      try {
                        createdAt = DateTime.parse(createdAtStr);
                      } catch (_) {}

                      final isExpanded = _expandedTraceId == id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () {
                                setState(() {
                                  _expandedTraceId = isExpanded ? null : id;
                                  if (_expandedTraceId != id) {
                                    _expandedEventIdx = null;
                                  }
                                });
                              },
                              leading: Icon(
                                isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                                color: Colors.grey,
                              ),
                              title: Text(
                                'Phiên: ${_truncateSessionId(sessionId)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _getRoleLabel(userRole),
                                        style: const TextStyle(color: Colors.purple, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (createdAt != null)
                                      Text(
                                        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} - ${createdAt.day}/${createdAt.month}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${events.length} sự kiện',
                                  style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            if (isExpanded)
                              Container(
                                color: isDark ? const Color(0xFF111827).withOpacity(0.5) : const Color(0xFFF9FAFB),
                                padding: const EdgeInsets.all(12),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: events.length,
                                  itemBuilder: (context, eIdx) {
                                    final event = events[eIdx];
                                    final String type = event['eventType'] ?? '';
                                    final String description = event['description'] ?? '';
                                    final int latency = (event['latencyMs'] as num?).maybeToInt() ?? 0;
                                    final String rawData = event['rawData'] ?? '';
                                    final String timestampStr = event['timestamp'] ?? '';

                                    DateTime? timestamp;
                                    try {
                                      timestamp = DateTime.parse(timestampStr);
                                    } catch (_) {}

                                    final isEventExpanded = _expandedEventIdx == eIdx;
                                    final evColor = _getEventColor(type);

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            onTap: () {
                                              setState(() {
                                                _expandedEventIdx = isEventExpanded ? null : eIdx;
                                              });
                                            },
                                            dense: true,
                                            leading: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: evColor.withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(_getEventIcon(type), color: evColor, size: 16),
                                            ),
                                            title: Text(
                                              _getEventTitle(type),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                            subtitle: Text(description, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (latency > 0)
                                                  Container(
                                                    margin: const EdgeInsets.only(right: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '$latency ms',
                                                      style: const TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                if (timestamp != null)
                                                  Text(
                                                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}',
                                                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isEventExpanded && rawData.isNotEmpty)
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(12),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF0F172A),
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft: Radius.circular(16),
                                                  bottomRight: Radius.circular(16),
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _formatEventSummary(rawData),
                                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                                                  ),
                                                  const Divider(color: Color(0xFF1E293B), height: 12),
                                                  SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: SelectableText(
                                                      _formatJSON(rawData),
                                                      style: const TextStyle(
                                                        color: Color(0xFFF1F5F9),
                                                        fontFamily: 'monospace',
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

extension LatencyToIntExtension on num? {
  int? maybeToInt() {
    if (this == null) return null;
    return this!.toInt();
  }
}
