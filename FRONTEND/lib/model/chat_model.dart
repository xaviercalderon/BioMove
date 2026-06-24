// model/chat_model.dart
class ChatMessageModel {
  final String id, senderId, receiverId, message, msgType;
  final String? refId, senderName;
  final bool isRead, isMine;
  final DateTime createdAt;

  const ChatMessageModel({
    required this.id, required this.senderId, required this.receiverId,
    required this.message, required this.msgType, required this.isRead,
    required this.isMine, required this.createdAt,
    this.refId, this.senderName,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
    id:          j['id'] ?? '',
    senderId:    j['sender_id'] ?? '',
    receiverId:  j['receiver_id'] ?? '',
    message:     j['message'] ?? '',
    msgType:     j['msg_type'] ?? 'text',
    refId:       j['ref_id'],
    senderName:  j['sender_name'],
    isRead:      j['is_read'] ?? false,
    isMine:      j['is_mine'] ?? false,
    createdAt:   j['created_at'] != null
        ? DateTime.tryParse(j['created_at'].toString()) ?? DateTime.now()
        : DateTime.now(),
  );
}

class ConversationModel {
  final String userId, displayName, role;
  final String? photoUrl, lastMessage;
  final bool isOnline;
  final int unreadCount;
  final DateTime? lastMessageAt;

  const ConversationModel({
    required this.userId, required this.displayName, required this.role,
    this.photoUrl, this.lastMessage, this.isOnline = false,
    this.unreadCount = 0, this.lastMessageAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) => ConversationModel(
    userId:       j['user_id'] ?? '',
    displayName:  j['display_name'] ?? '',
    role:         j['role'] ?? 'athlete',
    photoUrl:     j['photo_url'],
    lastMessage:  j['last_message'],
    isOnline:     j['is_online'] ?? false,
    unreadCount:  j['unread_count'] ?? 0,
    lastMessageAt: j['last_message_at'] != null
        ? DateTime.tryParse(j['last_message_at'].toString())
        : null,
  );
}
