import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:byure/services/auth_service.dart';
import 'package:byure/presentation/providers/auth_provider.dart';
import 'package:byure/services/user_service.dart';
import 'package:byure/services/location_service.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/presentation/widgets/swipeable_user_card.dart';
import 'package:byure/presentation/widgets/mesh_gradient_background.dart';
import 'package:byure/core/theme/app_theme.dart';
import 'package:byure/services/chat_service.dart';
import 'package:byure/presentation/screens/chat/chat_screen.dart';
import 'package:byure/domain/entities/chat_entity.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();
  final ChatService _chatService = ChatService();
  
  List<UserEntity> _nearbyUsers = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNearbyUsers();
  }

  Future<void> _loadNearbyUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AuthUser? currentUser;
      try {
        currentUser = ref.read(currentUserProvider);
      } catch (e) {
        debugPrint('Error reading current user: $e');
      }
      
      if (currentUser == null) {
        setState(() {
          _error = 'Please sign in to see nearby walkers';
          _isLoading = false;
        });
        return;
      }

      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        setState(() {
          _error = 'Unable to get your location. Please check your location settings.';
          _isLoading = false;
        });
        return;
      }

      final user = await _userService.getUserById(currentUser.id);
      final radius = user?.walkingPreferences.searchRadiusKm ?? 10.0;

      final walkers = await _userService.getNearbyWalkersForUser(
        userId: currentUser.id,
        radiusKm: radius,
        currentLocation: location,
      );

      setState(() {
        _nearbyUsers = walkers.map((w) => w.walker.toUserEntity()).toList();
        _currentIndex = 0; // Reset index when loading new users
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          final errorStr = e.toString();
          _error = errorStr.replaceFirst('Exception: ', '').replaceFirst('Exception:', '');
          _isLoading = false;
        });
      }
    }
  }

  void _onSwipeLeft() {
    // Pass
    _handleSwipe(false);
  }

  void _onSwipeRight() {
    // Like
    _handleSwipe(true);
  }

  Future<void> _handleSwipe(bool isLike) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null || _currentIndex >= _nearbyUsers.length) {
      _moveToNext();
      return;
    }

    // Get the user we just swiped on
    final targetUser = _nearbyUsers[_currentIndex];
    
    // Move UI first for responsiveness
    _moveToNext();

    try {
      // Create UserEntities for the service call
      final fullCurrentUser = await _userService.getUserById(currentUser.id);
      
      if (fullCurrentUser != null) {
        final matchId = await _chatService.swipeUser(
          currentUser: fullCurrentUser,
          targetUser: targetUser,
          isLike: isLike,
        );

        if (matchId != null && mounted) {
          _showMatchDialog(targetUser, matchId);
        }
      }
    } catch (e) {
      debugPrint('Error swiping: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  void _showMatchDialog(UserEntity matchedUser, String matchId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, AppTheme.primaryTeal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "NEW WALKING BUDDY!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 50,
                backgroundImage: matchedUser.photoUrls.isNotEmpty 
                    ? NetworkImage(matchedUser.photoUrls.first) 
                    : null,
                child: matchedUser.photoUrls.isEmpty 
                    ? Text(matchedUser.name[0], style: const TextStyle(fontSize: 32, color: AppTheme.primaryGreen)) 
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                "You and ${matchedUser.name} want to walk together!",
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Keep Swiping'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Navigate to ChatScreen
                        // We need a ChatEntity. Constructing one temporarily or fetching it?
                        // Constructing is faster.
                        // However, ChatScreen requires ChatEntity which has userId1, userId2 etc.
                        // We know the match ID and users.
                        
                        final chat = ChatEntity(
                          id: matchId,
                          userId1: ref.read(currentUserProvider)!.id,
                          userId2: matchedUser.id,
                          lastMessage: 'You matched! Say hi 👋',
                          lastMessageTime: DateTime.now(),
                          unreadCount: 0,
                          otherUserName: matchedUser.name,
                          otherUserPhotoUrl: matchedUser.photoUrls.isNotEmpty ? matchedUser.photoUrls.first : null,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: matchId,
                              chat: chat,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text('Say Hi 👋'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _moveToNext() {
    if (_currentIndex < _nearbyUsers.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // No more users
      setState(() {
        _nearbyUsers = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Watch for auth changes to reload users if they were missed on start
    ref.listen(currentUserProvider, (previous, next) {
      if (previous == null && next != null) {
        _loadNearbyUsers();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Discover',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: MeshGradientBackground(
        isDark: isDark,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : _nearbyUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildCardStack(),
      ),
    );
  }

  Widget _buildErrorState() {
    final needsPermission = _error!.toLowerCase().contains('permission');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              needsPermission ? Icons.location_off : Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadNearbyUsers,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
                if (needsPermission) ...[
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      // Open app settings
                      await openAppSettings();
                      // Wait a bit then try again
                      await Future.delayed(const Duration(seconds: 1));
                      _loadNearbyUsers();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 60,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No more walkers nearby',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later or expand your search radius',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadNearbyUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack() {
    if (_nearbyUsers.isEmpty || _currentIndex >= _nearbyUsers.length) {
      return _buildEmptyState();
    }
    
    final visibleCards = _nearbyUsers.length - _currentIndex;
    final cardsToShow = math.min(visibleCards, 3); // Show max 3 cards in stack

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: List.generate(cardsToShow, (index) {
              final userIndex = _currentIndex + index;
              if (userIndex >= _nearbyUsers.length) return const SizedBox.shrink();

              final user = _nearbyUsers[userIndex];
              final isTopCard = index == 0;

              return Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: index * 8.0,
                    left: index * 4.0,
                    right: index * 4.0,
                  ),
                  child: Opacity(
                    opacity: 1.0 - (index * 0.15),
                    child: Transform.scale(
                      scale: 1.0 - (index * 0.05),
                      child: SwipeableUserCard(
                        key: ValueKey(user.id),
                        user: user,
                        onSwipeLeft: isTopCard ? _onSwipeLeft : null,
                        onSwipeRight: isTopCard ? _onSwipeRight : null,
                        isInteractive: isTopCard, // Only top card is interactive
                        onTap: () {
                          // TODO: Show user profile
                        },
                      ),
                    ),
                  ),
                ),
              );
            }).reversed.toList(), // Reverse to put top card (index 0) on top of stack
          ),
        ),
        
        // Action buttons
        if (_currentIndex < _nearbyUsers.length)
          _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          _buildActionButton(
            icon: Icons.close,
            color: Colors.red,
            onPressed: _onSwipeLeft,
            size: 56,
          ),
          const SizedBox(width: 24),
          
          // Super like button (optional)
          _buildActionButton(
            icon: Icons.star,
            color: Colors.blue,
            onPressed: () {
              // TODO: Implement super like
              _onSwipeRight();
            },
            size: 48,
          ),
          const SizedBox(width: 24),
          
          // Like button
          _buildActionButton(
            icon: Icons.favorite,
            color: AppTheme.primaryGreen,
            onPressed: _onSwipeRight,
            size: 56,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: size * 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
