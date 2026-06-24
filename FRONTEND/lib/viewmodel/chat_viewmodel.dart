// viewmodel/chat_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/chat_model.dart';
import '../repository/chat_repository.dart';
import '../services/websocket_service.dart';
import '../services/notification_service.dart';

class ChatViewModel extends ChangeNotifier {
  final _repo  = ChatRepository();
  final _ws    = WebSocketService();
  final _notif = NotificationService();

  List<ConversationModel> _conversations = [];
  List<ChatMessageModel>  _messages      = [];
  String?  _currentOtherId;
  bool     _isLoading = false;
  String?  _error;
  final Set<String> _onlineUsers = {};

  List<ConversationModel> get conversations => _conversations;
  List<ChatMessageModel>  get messages      => _messages;
  bool    get isLoading => _isLoading;
  String? get error     => _error;

  bool isOtherOnline(String userId) =>
      _ws.isConnected && _onlineUsers.contains(userId);

  Future<void> initWebSocket() async {
    try {
      final user  = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await user.getIdToken();
      if (token != null) {
        await _ws.connect(user.uid, token);
        _ws.addListener2(_onWsMessage);
      }
    } catch (e) {
      debugPrint('ChatViewModel WebSocket init error: $e');
    }
  }

  void _onWsMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    switch (type) {
      case 'message':
        final msg = ChatMessageModel.fromJson(data);
        final isSentConfirm = data['status'] == 'sent';
        if (isSentConfirm) {
          // Confirmación del propio mensaje → reemplazar el optimista
          final optIdx = _messages.indexWhere(
              (m) => m.id.startsWith('opt_') && m.message == msg.message);
          if (optIdx >= 0) {
            _messages[optIdx] = msg;
          }
          notifyListeners();
          break;
        }
        // Mensaje entrante de otro usuario
        if (msg.senderId == _currentOtherId ||
            msg.receiverId == _currentOtherId) {
          _messages.add(msg);
          notifyListeners();
        } else {
          // Notificación push si el chat no está abierto
          _notif.showSessionReminder(
            exerciseLabel: 'Mensaje nuevo',
            prescription: '${msg.senderName ?? 'Tu entrenador'}: ${msg.message}',
          );
          // Actualizar unread en la lista de conversaciones
          final idx = _conversations.indexWhere(
              (c) => c.userId == msg.senderId);
          if (idx >= 0) {
            final c = _conversations[idx];
            _conversations[idx] = ConversationModel(
              userId: c.userId, displayName: c.displayName,
              photoUrl: c.photoUrl, role: c.role,
              isOnline: c.isOnline,
              unreadCount: c.unreadCount + 1,
              lastMessage: msg.message,
              lastMessageAt: msg.createdAt,
            );
            notifyListeners();
          }
        }
        break;
      case 'pong':
        break;
      case 'report_shared':
        loadConversations();
        break;
    }
  }

  Future<void> loadConversations() async {
    _isLoading = true; notifyListeners();
    try {
      final data = await _repo.getConversations();
      _conversations = (data['conversations'] as List? ?? [])
          .map((c) => ConversationModel.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  Future<void> loadMessages(String otherUserId) async {
    _currentOtherId = otherUserId;
    _isLoading = true; notifyListeners();
    try {
      final data = await _repo.getMessages(otherUserId);
      _messages = (data['messages'] as List? ?? [])
          .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false; notifyListeners();
    }
  }

  void sendMessage({required String receiverId, required String message,
      String msgType = 'text', String? refId}) {
    _ws.sendMessage(receiverId: receiverId, message: message,
        msgType: msgType, refId: refId);
    // Agregar optimistamente a la UI — is_mine=true, senderId vacío intencional
    // para no depender del Firebase UID vs DB UUID
    _messages.add(ChatMessageModel(
      id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
      senderId: '_me_',
      receiverId: receiverId,
      message: message, msgType: msgType, refId: refId,
      isRead: false, isMine: true,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<void> sendReport(String coachId, String sessionId) async {
    try {
      await _repo.sendReport(coachId: coachId, sessionId: sessionId);
    } catch (e) {
      _error = e.toString(); notifyListeners();
    }
  }

  void sendAnalysisProgress({required String coachId, required String jobId,
      required int progress, required String status}) {
    _ws.sendAnalysisProgress(coachId: coachId, jobId: jobId,
        progress: progress, status: status);
  }

  void clearCurrentChat() {
    _currentOtherId = null;
    _messages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _ws.removeListener2(_onWsMessage);
    super.dispose();
  }
}
