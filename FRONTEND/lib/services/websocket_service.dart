// services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/utils/app_constants.dart';

typedef MessageCallback = void Function(Map<String, dynamic> data);

class WebSocketService extends ChangeNotifier {
  static final WebSocketService _i = WebSocketService._();
  factory WebSocketService() => _i;
  WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _connected = false;
  String? _userId;

  final List<MessageCallback> _listeners = [];

  bool get isConnected => _connected;

  // Convierte la URL base HTTP → WS
  static String get wsBase {
    final base = AppConstants.baseUrl;
    return base.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
  }

  Future<void> connect(String userId, String firebaseToken) async {
    if (_connected && _userId == userId) return;
    await disconnect();
    _userId = userId;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsBase/chat/ws/$userId?token=$firebaseToken'),
      );
      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      _connected = true;
      notifyListeners();
      debugPrint('WebSocket conectado: $userId');
      // Ping cada 30s para mantener la conexión
      Timer.periodic(const Duration(seconds: 30), (_) {
        if (_connected) sendRaw({'type': 'ping'});
      });
    } catch (e) {
      debugPrint('WebSocket error al conectar: $e');
      _connected = false;
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      for (final cb in List<MessageCallback>.from(_listeners)) {
        cb(data);
      }
    } catch (e) {
      debugPrint('WebSocket parse error: $e');
    }
  }

  void _onError(dynamic err) {
    debugPrint('WebSocket error: $err');
    _connected = false;
    notifyListeners();
  }

  void _onDone() {
    debugPrint('WebSocket cerrado');
    _connected = false;
    notifyListeners();
  }

  void sendMessage({
    required String receiverId,
    required String message,
    String msgType = 'text',
    String? refId,
  }) {
    sendRaw({
      'type':        'message',
      'receiver_id': receiverId,
      'message':     message,
      'msg_type':    msgType,
      if (refId != null) 'ref_id': refId,
    });
  }

  void sendAnalysisProgress({
    required String coachId,
    required String jobId,
    required int progress,
    required String status,
  }) {
    sendRaw({
      'type':     'analysis_progress',
      'coach_id': coachId,
      'job_id':   jobId,
      'progress': progress,
      'status':   status,
    });
  }

  void sendRaw(Map<String, dynamic> data) {
    if (!_connected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('WebSocket send error: $e');
    }
  }

  void addListener2(MessageCallback cb) {
    if (!_listeners.contains(cb)) _listeners.add(cb);
  }

  void removeListener2(MessageCallback cb) {
    _listeners.remove(cb);
  }

  Future<void> disconnect() async {
    _sub?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _connected = false;
    _userId = null;
    notifyListeners();
  }
}
