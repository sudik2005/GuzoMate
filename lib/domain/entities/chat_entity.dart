/// Chat message entity
class ChatMessageEntity {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl; // For images, etc.

  ChatMessageEntity({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    this.attachmentUrl,
  });
}

enum MessageType {
  text,
  image,
  walkInvite,
  location,
}

/// Chat conversation entity
class ChatEntity {
  final String id;
  final String userId1;
  final String userId2;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? otherUserId; // The other user in the chat
  final String? otherUserName;
  final String? otherUserPhotoUrl;

  ChatEntity({
    required this.id,
    required this.userId1,
    required this.userId2,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCount,
    this.otherUserId,
    this.otherUserName,
    this.otherUserPhotoUrl,
  });
}

