import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WalkerMarkerInfoWindow extends StatelessWidget {
  final UserEntity user;

  const WalkerMarkerInfoWindow({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User photo and basic info
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: user.photoUrls.isNotEmpty
                    ? CachedNetworkImageProvider(user.photoUrls.first)
                    : null,
                child: user.photoUrls.isEmpty
                    ? Text(user.name[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${user.age} years old',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (user.bio != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Walking preferences
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(
                  'Pace: ${user.walkingPreferences.pace.name}',
                ),
                backgroundColor: Colors.green.shade50,
              ),
              Chip(
                label: Text(
                  '${user.walkingPreferences.preferredDistanceKm} km',
                ),
                backgroundColor: Colors.blue.shade50,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Interests
          if (user.interests.isNotEmpty) ...[
            Text(
              'Interests',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.interests.take(5).map((interest) {
                return Chip(
                  label: Text(interest),
                  backgroundColor: Colors.orange.shade50,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/walk-invite/${user.id}');
                  },
                  child: const Text('Send Walk Invite'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


