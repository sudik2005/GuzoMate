import 'package:byure/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:byure/domain/entities/chat_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatListItem extends StatelessWidget {
  final ChatEntity chat;

  const ChatListItem({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            context.push('/chat/${chat.id}', extra: chat);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                  backgroundImage: chat.otherUserPhotoUrl != null
                      ? CachedNetworkImageProvider(chat.otherUserPhotoUrl!)
                      : null,
                  child: chat.otherUserPhotoUrl == null
                      ? Text(
                          (chat.otherUserName != null && chat.otherUserName!.isNotEmpty)
                              ? chat.otherUserName![0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.otherUserName ?? 'Unknown',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.lastMessageTime != null)
                            Text(
                              timeago.format(chat.lastMessageTime!, locale: 'en_short'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage ?? 'No messages yet',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: chat.unreadCount > 0
                                    ? (isDark ? Colors.white : Colors.black87)
                                    : Colors.grey.shade600,
                                fontWeight: chat.unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (chat.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${chat.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


