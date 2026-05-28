import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:byure/domain/entities/chat_entity.dart';
import 'package:byure/presentation/widgets/chat_list_item.dart';
import 'package:byure/presentation/widgets/mesh_gradient_background.dart';
import 'package:byure/core/theme/app_theme.dart';
import 'package:byure/presentation/providers/navigation_provider.dart';
import 'package:byure/services/chat_service.dart';
import 'package:byure/presentation/providers/auth_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, size: 20),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat search is coming soon')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: MeshGradientBackground(
        isDark: isDark,
        child: StreamBuilder<List<ChatEntity>>(
          stream: _chatService.getMatches(currentUser.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final chats = snapshot.data ?? [];

            if (chats.isEmpty) {
              return _buildEmptyState(isDark);
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final chat = chats[index];
                return GestureDetector(
                    onTap: () {
                        // Navigate to Chat Screen (we will create this next)
                        context.push('/chat/${chat.id}', extra: chat);
                    },
                    child: ChatListItem(chat: chat),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: AppTheme.primaryTeal,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Connect with nearby walkers to\nstart a conversation!',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // Switch to Matches tab (index 1)
              ref.read(homeTabIndexProvider.notifier).state = 1;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Find Buddies'),
          ),
        ],
      ),
    );
  }
}


