// repository/chat_repository.dart
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/utils/app_constants.dart';

class ChatRepository {
  late final Dio _dio;

  ChatRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 1),
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken(false);
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
        } catch (_) {}
        handler.next(options);
      },
    ));
  }

  Future<Map<String, dynamic>> getConversations() async {
    final r = await _dio.get('/chat/conversations');
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> getMessages(String otherUserId,
      {int limit = 50}) async {
    final r = await _dio.get('/chat/messages/$otherUserId',
        queryParameters: {'limit': limit});
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> sendMessage({
    required String receiverId, required String message,
    String msgType = 'text', String? refId,
  }) async {
    final r = await _dio.post('/chat/send', queryParameters: {
      'receiver_id': receiverId, 'message': message,
      'msg_type': msgType, if (refId != null) 'ref_id': refId,
    });
    return Map<String, dynamic>.from(r.data);
  }

  Future<Map<String, dynamic>> sendReport({
    required String coachId, required String sessionId,
    String message = 'Te comparto mi último análisis',
  }) async {
    final r = await _dio.post('/chat/send-report/$coachId',
        queryParameters: {'session_id': sessionId, 'message': message});
    return Map<String, dynamic>.from(r.data);
  }
}
