// view/screens/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../viewmodel/chat_viewmodel.dart';
import '../../../core/theme/app_theme.dart';
import '../../../view/widgets/common_widgets.dart';
import '../../../model/chat_model.dart';




class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        title: const Text('Mensajes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Consumer<ChatViewModel>(
        builder: (ctx, vm, _) {
          if (vm.isLoading) return const Center(
              child: CircularProgressIndicator(color: BM.accent));
          if (vm.conversations.isEmpty) return _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.conversations.length,
            itemBuilder: (_, i) {
              final conv = vm.conversations[i];
              return _ConversationTile(
                conversation: conv,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    otherUserId:   conv.userId,
                    otherUserName: conv.displayName,
                    otherPhotoUrl: conv.photoUrl,
                    otherRole:     conv.role,
                  ),
                )),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 50));
            },
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  const _ConversationTile({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BM.card, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: conversation.unreadCount > 0
              ? BM.accent.withOpacity(0.3) : Colors.white.withOpacity(0.06)),
        ),
        child: Row(children: [
          Stack(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: BM.primary.withOpacity(0.2),
              backgroundImage: conversation.photoUrl != null
                  ? NetworkImage(conversation.photoUrl!) : null,
              child: conversation.photoUrl == null
                  ? Text(conversation.displayName.isNotEmpty
                      ? conversation.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(color: BM.primary,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            if (conversation.isOnline)
              Positioned(right: 0, bottom: 0,
                child: Container(width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: BM.accent, shape: BoxShape.circle,
                    border: Border.all(color: BM.bg, width: 2)))),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(conversation.displayName,
                  style: const TextStyle(color: BM.textPrimary,
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 6),
              RoleBadge(role: conversation.role),
            ]),
            const SizedBox(height: 3),
            Text(conversation.lastMessage ?? 'Sin mensajes aún',
                style: TextStyle(
                    color: conversation.unreadCount > 0
                        ? BM.textPrimary : BM.textSecondary,
                    fontSize: 12,
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w600 : FontWeight.normal),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (conversation.lastMessageAt != null)
              Text(_formatTime(conversation.lastMessageAt!),
                  style: const TextStyle(color: BM.textHint, fontSize: 10)),
            const SizedBox(height: 4),
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: const BoxDecoration(
                    color: BM.accent, shape: BoxShape.circle),
                child: Text('${conversation.unreadCount}',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w700))),
          ]),
        ]),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) return DateFormat('HH:mm').format(dt);
    return DateFormat('d MMM', 'es').format(dt);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.chat_bubble_outline_rounded, color: BM.textHint, size: 60)
          .animate().scale(duration: 400.ms, curve: Curves.elasticOut),
      const SizedBox(height: 20),
      const Text('Sin conversaciones aún',
          style: TextStyle(color: BM.textPrimary,
              fontWeight: FontWeight.w600, fontSize: 18)),
      const SizedBox(height: 10),
      const Text('Vincúlate con un entrenador para empezar a chatear',
          style: TextStyle(color: BM.textSecondary, fontSize: 13),
          textAlign: TextAlign.center),
      const SizedBox(height: 24),
      GBtn(text: 'Vincularme con entrenador', height: 48,
          onTap: () => context.go('/link-coach')),
    ]));
}

// ── ChatRoom ──────────────────────────────────────────────────────────────────
class ChatRoomScreen extends StatefulWidget {
  final String otherUserId, otherUserName, otherRole;
  final String? otherPhotoUrl;
  const ChatRoomScreen({
    super.key, required this.otherUserId, required this.otherUserName,
    required this.otherRole, this.otherPhotoUrl,
  });
  @override State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatViewModel>().loadMessages(widget.otherUserId);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: 300.ms, curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BM.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/chat');
            }
          },
        ),
        title: Row(children: [
          CircleAvatar(radius: 16,
            backgroundColor: BM.primary.withOpacity(0.2),
            backgroundImage: widget.otherPhotoUrl != null
                ? NetworkImage(widget.otherPhotoUrl!) : null,
            child: widget.otherPhotoUrl == null
                ? Text(widget.otherUserName[0].toUpperCase(),
                    style: const TextStyle(color: BM.primary, fontSize: 13)) : null),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherUserName, style: const TextStyle(fontSize: 14)),
            Consumer<ChatViewModel>(
              builder: (_, vm, __) => Text(
                vm.isOtherOnline(widget.otherUserId) ? 'En línea' : 'Desconectado',
                style: TextStyle(fontSize: 10,
                    color: vm.isOtherOnline(widget.otherUserId)
                        ? BM.accent : BM.textHint)),
            ),
          ]),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: Consumer<ChatViewModel>(
            builder: (ctx, vm, _) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
              if (vm.messages.isEmpty) return Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chat_rounded, color: BM.textHint, size: 40),
                  const SizedBox(height: 12),
                  Text('Empieza la conversación con ${widget.otherUserName}',
                      style: const TextStyle(color: BM.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center),
                ]));

              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: vm.messages.length,
                itemBuilder: (_, i) {
                  final msg  = vm.messages[i];
                  return _MessageBubble(msg: msg, isMine: msg.isMine)
                      .animate().fadeIn(delay: Duration(milliseconds: i * 20));
                },
              );
            },
          ),
        ),

        // Input
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 8, top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom + 10),
          decoration: BoxDecoration(
            color: BM.card,
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06)))),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: BM.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  hintStyle: const TextStyle(color: BM.textHint),
                  filled: true, fillColor: BM.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10)),
                maxLines: 3, minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)])),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: _send,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    context.read<ChatViewModel>().sendMessage(
      receiverId: widget.otherUserId, message: text);
    _ctrl.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMine;
  const _MessageBubble({required this.msg, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final isReport = msg.msgType == 'report';
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMine
              ? const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)])
              : null,
          color: isMine ? null : BM.card,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(16),
            topRight:    const Radius.circular(16),
            bottomLeft:  Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine ? null
              : Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isReport) ...[
            Row(children: const [
              Icon(Icons.analytics_rounded, color: BM.accent, size: 14),
              SizedBox(width: 4),
              Text('Informe compartido',
                  style: TextStyle(color: BM.accent,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
          ],
          Text(msg.message,
              style: TextStyle(
                  color: isMine ? Colors.white : BM.textPrimary,
                  fontSize: 14)),
          const SizedBox(height: 4),
          Text(DateFormat('HH:mm').format(msg.createdAt),
              style: TextStyle(
                  color: isMine
                      ? Colors.white.withOpacity(0.6) : BM.textHint,
                  fontSize: 10)),
        ]),
      ),
    );
  }
}
