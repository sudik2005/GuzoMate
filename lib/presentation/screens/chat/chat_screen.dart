import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:byure/core/theme/app_theme.dart';
import 'package:byure/domain/entities/chat_entity.dart';
import 'package:byure/presentation/providers/auth_provider.dart';
import 'package:byure/presentation/widgets/mesh_gradient_background.dart';
import 'package:byure/services/chat_service.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/presentation/screens/walk/live_tracking_screen.dart';
import 'package:intl/intl.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final ChatEntity chat;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chat,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final receiverId = widget.chat.userId1 == currentUser.id 
        ? widget.chat.userId2 
        : widget.chat.userId1;

    _chatService.sendMessage(
      chatId: widget.chatId,
      senderId: currentUser.id,
      receiverId: receiverId,
      content: text,
    );

    _textController.clear();
    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.chat.otherUserPhotoUrl != null
                  ? NetworkImage(widget.chat.otherUserPhotoUrl!)
                  : null,
              child: widget.chat.otherUserPhotoUrl == null
                  ? Text((widget.chat.otherUserName != null && widget.chat.otherUserName!.isNotEmpty)
                      ? widget.chat.otherUserName![0]
                      : '?')
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.chat.otherUserName ?? 'Chat',
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen),
            tooltip: 'Track Buddy',
            onPressed: () {
              // Construct a minimal UserEntity for the tracking screen
              final otherUser = UserEntity(
                id: widget.chat.userId1 == currentUser?.id ? widget.chat.userId2 : widget.chat.userId1,
                name: widget.chat.otherUserName ?? 'Buddy',
                photoUrls: widget.chat.otherUserPhotoUrl != null ? [widget.chat.otherUserPhotoUrl!] : [],
                email: '', age: 0, interests: [], walkingPreferences: WalkingPreferences(pace: WalkingPace.moderate, preferredDistanceKm: 5, preferredTerrains: [], preferredTimes: []), isAvailableToWalk: true, isPremium: false, createdAt: DateTime.now(), safetySettings: SafetySettings(shareLocationWithTrustedContacts: false, trustedContactIds: [], enableSOS: true)
              );
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LiveTrackingScreen(buddy: otherUser),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MeshGradientBackground(
        isDark: isDark,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessageEntity>>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        'Say hi! 👋',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  final messages = snapshot.data!;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUser?.id;
                      return _buildMessageBubble(msg, isMe, isDark);
                    },
                  );
                },
              ),
            ),
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageEntity message, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe 
              ? AppTheme.primaryGreen 
              : (isDark ? Colors.grey[800] : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe 
                    ? Colors.white 
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: TextStyle(
                color: isMe 
                    ? Colors.white70 
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
