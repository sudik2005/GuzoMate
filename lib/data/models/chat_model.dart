import 'package:byure/domain/entities/chat_entity.dart';

class ChatModel extends ChatEntity {
  ChatModel({
    required super.id,
    required super.userId1,
    required super.userId2,
    super.lastMessage,
    super.lastMessageTime,
    required super.unreadCount,
    super.otherUserId,
    super.otherUserName,
    super.otherUserPhotoUrl,
  });

  /// Supabase usually returns a JOINED response.
  /// E.g. matches SELECT *, user1:users!userId1(*), user2:users!userId2(*)
  factory ChatModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    
    final u1 = json['user_id_1'] as String;
    final u2 = json['user_id_2'] as String;
    final isUser1Me = u1 == currentUserId;
    
    final otherId = isUser1Me ? u2 : u1;
    
    // Supabase returns relations as nested objects if queried correctly
    // We expect the query to expand user details.
    // Let's assume the query is: select *, user1:users!user_id_1(*), user2:users!user_id_2(*)
    
    final user1Data = json['user1'] ?? {}; // Map <String, dynamic>
    final user2Data = json['user2'] ?? {};
    
    final otherData = isUser1Me ? user2Data : user1Data;
    
    return ChatModel(
      id: json['id'],
      userId1: u1,
      userId2: u2,
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'] != null ? DateTime.parse(json['last_message_time']) : null,
      unreadCount: 0, 
      otherUserId: otherId,
      otherUserName: otherData['name'],
      // Handle array or string for photo_url
      otherUserPhotoUrl: otherData['photo_url'], 
    );
  }
}

class ChatMessageModel extends ChatMessageEntity {
  ChatMessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.type,
    required super.timestamp,
    required super.isRead,
    super.attachmentUrl,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      chatId: json['match_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: '', // Usually derived from chat context or we need to fetch it
      content: json['content'] ?? '',
      type: MessageType.text, // Default to text for now
      timestamp: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      isRead: json['is_read'] ?? false,
      attachmentUrl: null, // Add to schema if needed
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'match_id': chatId,
      'sender_id': senderId,
      'content': content,
      // 'created_at': timestamp.toIso8601String(), // Auto-generated
    };
  }
}
