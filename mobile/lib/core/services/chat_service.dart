import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'api_service.dart';

class ChatService extends ChangeNotifier {
  HubConnection? _connection;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Stream để UI lắng nghe sự kiện realtime
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _newMessageController = StreamController<void>.broadcast();
  final _staffAssignedController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<void> get newMessageStream => _newMessageController.stream;
  Stream<Map<String, dynamic>> get staffAssignedStream =>
      _staffAssignedController.stream;

  // Khởi tạo kết nối SignalR Hub
  Future<void> connect() async {
    if (_connection != null &&
        _connection!.state == HubConnectionState.Connected) {
      return;
    }

    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) {
      print('ChatService: Cannot connect, token is null or empty');
      return;
    }

    // Convert baseUrl sang chatHub URL
    // static const String baseUrl = 'https://phone-store-api-4bah.onrender.com/api';
    // => 'https://phone-store-api-4bah.onrender.com/chatHub'
    final hubUrl = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '/chatHub');

    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              skipNegotiation: true,
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Lắng nghe sự kiện từ máy chủ
      _connection!.on('ReceiveMessage', _handleReceiveMessage);
      _connection!.on('NewMessage', _handleNewMessage);
      _connection!.on('StaffAssigned', _handleStaffAssigned);

      await _connection!.start();
      _isConnected = true;
      print('ChatService: SignalR Connected successfully to $hubUrl');
      notifyListeners();
    } catch (e) {
      print('ChatService: Connection failed: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  // Ngắt kết nối
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.stop();
      } catch (e) {
        print('ChatService: Error stopping connection: $e');
      } finally {
        _connection = null;
        _isConnected = false;
        print('ChatService: SignalR Disconnected');
        notifyListeners();
      }
    }
  }

  // Gọi nhóm JoinStaff (cho Staff)
  Future<void> joinStaff() async {
    if (_connection == null ||
        _connection!.state != HubConnectionState.Connected) {
      print('ChatService: Cannot JoinStaff, not connected');
      return;
    }
    try {
      await _connection!.invoke('JoinStaff');
      print('ChatService: Joined Staff group');
    } catch (e) {
      print('ChatService: Error joining staff group: $e');
    }
  }

  // Tham gia vào phiên chat cụ thể
  Future<void> joinSession(String sessionId) async {
    if (_connection == null ||
        _connection!.state != HubConnectionState.Connected) {
      print('ChatService: Cannot JoinSession, not connected');
      return;
    }
    try {
      await _connection!.invoke('JoinSession', args: [sessionId]);
      print('ChatService: Joined session: $sessionId');
    } catch (e) {
      print('ChatService: Error joining session: $e');
    }
  }

  // --- Handlers cho các sự kiện của server ---
  void _handleReceiveMessage(List<dynamic>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      try {
        final messageData = arguments[0] as Map<String, dynamic>;
        _messageController.add(messageData);
      } catch (e) {
        print('ChatService: Error parsing ReceiveMessage argument: $e');
      }
    }
  }

  void _handleNewMessage(List<dynamic>? arguments) {
    _newMessageController.add(null);
  }

  void _handleStaffAssigned(List<dynamic>? arguments) {
    if (arguments != null && arguments.isNotEmpty) {
      try {
        final sessionData = arguments[0] as Map<String, dynamic>;
        _staffAssignedController.add(sessionData);
      } catch (e) {
        print('ChatService: Error parsing StaffAssigned argument: $e');
      }
    }
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    _newMessageController.close();
    _staffAssignedController.close();
    super.dispose();
  }
}
