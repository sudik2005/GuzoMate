import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:byure/domain/entities/match_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class MatchCard extends StatelessWidget {
  final MatchEntity match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final otherUser = match.otherUser;
    if (otherUser == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to chat or profile
          context.push('/chat');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile photo
              Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: otherUser.photoUrls.isNotEmpty
                        ? CachedNetworkImageProvider(otherUser.photoUrls.first)
                        : null,
                    child: otherUser.photoUrls.isEmpty
                        ? Text(otherUser.name[0].toUpperCase())
                        : null,
                  ),
                  if (match.status == MatchStatus.accepted)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${otherUser.age} years old',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (match.compatibilityScore != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(match.compatibilityScore! * 100).toInt()}% match',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Matched ${_formatDate(match.matchedAt)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Action button
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  // TODO: Navigate to chat
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}


