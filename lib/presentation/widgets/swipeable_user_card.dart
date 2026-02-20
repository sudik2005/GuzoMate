
import 'package:flutter/material.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/core/theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SwipeableUserCard extends StatefulWidget {
  final UserEntity user;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onTap;
  final bool isInteractive;

  const SwipeableUserCard({
    super.key,
    required this.user,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTap,
    this.isInteractive = true,
  });

  @override
  State<SwipeableUserCard> createState() => _SwipeableUserCardState();
}

class _SwipeableUserCardState extends State<SwipeableUserCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideOutAnimation;
  
  double _dragPosition = 0;
  double _rotation = 0;
  bool _isSlidingOut = false;
  
  // To track which way we are sliding out
  double _slideOutDirection = 0; 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Default dummy animation
    _slideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isSlidingOut) {
        if (_slideOutDirection > 0) {
          widget.onSwipeRight?.call();
        } else {
          widget.onSwipeLeft?.call();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerSwipe(double direction) {
    if (_isSlidingOut) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    _isSlidingOut = true;
    _slideOutDirection = direction;

    final endX = direction > 0 ? screenWidth * 1.5 : -screenWidth * 1.5;

    setState(() {
      _slideOutAnimation = Tween<Offset>(
        begin: Offset(_dragPosition, 0),
        end: Offset(endX, 0),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
    });
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Base card widget (visuals only)
    final cardWidget = AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
       final slideOffset = _isSlidingOut ? _slideOutAnimation.value.dx : _dragPosition;
        // Keep rotation consistent during slide out
        final currentRotation = _isSlidingOut 
            ? (slideOffset / screenWidth * 0.2) 
            : _rotation;

        return Transform(
          alignment: Alignment.center, // Rotate from center
          transform: Matrix4.identity()
            ..translate(slideOffset, 0.0, 0.0)
            ..rotateZ(currentRotation),
          child: Container(
            height: screenHeight * 0.7,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Background image
                  _buildBackgroundImage(),
                  
                  // Gradient overlay
                  _buildGradientOverlay(),
                  
                  // Swipe indicators
                  if (slideOffset > 50) _buildLikeIndicator(),
                  if (slideOffset < -50) _buildPassIndicator(),
                  
                  // User info
                  _buildUserInfo(),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!widget.isInteractive) {
      return cardWidget;
    }

    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: (_) {
        if (_isSlidingOut) return;
      },
      onPanUpdate: (details) {
        if (_isSlidingOut) return;
        setState(() {
          _dragPosition += details.delta.dx;
          _rotation = _dragPosition / screenWidth * 0.15;
        });
      },
      onPanEnd: (details) {
        if (_isSlidingOut) return;
        
        final threshold = screenWidth * 0.3; // Trigger at 30% width
        final velocity = details.velocity.pixelsPerSecond.dx;
        
        // Check if we should swipe
        if (_dragPosition.abs() > threshold || velocity.abs() > 800) {
          final direction = _dragPosition > 0 || velocity > 800 ? 1.0 : -1.0;
          _triggerSwipe(direction);
        } else {
          // Snap back
          setState(() {
            _dragPosition = 0;
            _rotation = 0;
          });
        }
      },
      child: cardWidget,
    );
  }

  Widget _buildBackgroundImage() {
    if (widget.user.photoUrls.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.user.photoUrls.first,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade300,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(),
      );
    } else {
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreenDark,
          ],
        ),
      ),
      child: Center(
        child: Text(
          widget.user.name[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 80,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeIndicator() {
    return Positioned(
      top: 50,
      left: 20,
      child: Transform.rotate(
        angle: -0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green, width: 4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'LIKE',
            style: TextStyle(
              color: Colors.green,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassIndicator() {
    return Positioned(
      top: 50,
      right: 20,
      child: Transform.rotate(
        angle: 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'PASS',
            style: TextStyle(
              color: Colors.red,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and age
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.user.name}, ${widget.user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.user.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Premium',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Bio
            if (widget.user.bio != null && widget.user.bio!.isNotEmpty) ...[
              Text(
                widget.user.bio!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 8,
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],
            
            // Walking preferences
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  icon: Icons.directions_walk,
                  label: widget.user.walkingPreferences.pace.name,
                ),
                _buildInfoChip(
                  icon: Icons.straighten,
                  label: '${widget.user.walkingPreferences.preferredDistanceKm} km',
                ),
                if (widget.user.walkingPreferences.preferredTerrains.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.terrain,
                    label: widget.user.walkingPreferences.preferredTerrains.first.name,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Interests
            if (widget.user.interests.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.user.interests.take(3).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

