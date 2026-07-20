import 'package:signalr_netcore/signalr_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ReviewSignalRService {
  HubConnection? _connection;
  bool _isConnected = false;

  final Function(dynamic) onReceiveReview;
  final Function(String) onReceiveReviewDelete;
  final Function(dynamic) onReceiveReviewReply;

  ReviewSignalRService({
    required this.onReceiveReview,
    required this.onReceiveReviewDelete,
    required this.onReceiveReviewReply,
  });

  Future<void> initConnection(String productId) async {
    final serverUrl = ApiService.baseUrl.replaceAll('/api', '/reviewHub');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    _connection = HubConnectionBuilder()
        .withUrl(serverUrl, options: HttpConnectionOptions(
          accessTokenFactory: token != null ? () async => token : null,
        ))
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveReview', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        onReceiveReview(arguments[0]);
      }
    });

    _connection!.on('ReceiveReviewDelete', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        onReceiveReviewDelete(arguments[0].toString());
      }
    });

    _connection!.on('ReceiveReviewReply', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        onReceiveReviewReply(arguments[0]);
      }
    });

    try {
      await _connection!.start();
      _isConnected = true;
      print('SignalR (Reviews) Connected');
      
      // Join product group
      await _connection!.invoke('JoinProductGroup', args: [productId]);
      print('Joined product group: $productId');
    } catch (e) {
      print('SignalR Connection Error: $e');
    }
  }

  Future<void> dispose(String productId) async {
    if (_connection != null && _isConnected) {
      try {
        await _connection!.invoke('LeaveProductGroup', args: [productId]);
        await _connection!.stop();
      } catch (e) {
        print('SignalR Stop Error: $e');
      }
    }
  }
}
