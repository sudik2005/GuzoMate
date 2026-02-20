import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:byure/core/theme/app_theme.dart';

class MeshGradientBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const MeshGradientBackground({
    super.key,
    required this.child,
    this.isDark = false,
  });

  @override
  State<MeshGradientBackground> createState() => _MeshGradientBackgroundState();
}

class _MeshGradientBackgroundState extends State<MeshGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BlobData> _blobs = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Initialize random blobs
    for (int i = 0; i < 4; i++) {
      _blobs.add(_generateRandomBlob());
    }
  }

  _BlobData _generateRandomBlob() {
    return _BlobData(
      alignment: Alignment(
        _random.nextDouble() * 2 - 1,
        _random.nextDouble() * 2 - 1,
      ),
      color: _getRandomColor(),
      radius: _random.nextDouble() * 1.5 + 0.5, // 0.5 to 2.0 screen width
    );
  }

  Color _getRandomColor() {
    final colors = widget.isDark
        ? [
            AppTheme.primaryGreen.withValues(alpha: 0.3),
            AppTheme.primaryTeal.withValues(alpha: 0.3),
            Colors.purple.withValues(alpha: 0.2),
            Colors.blue.withValues(alpha: 0.2),
          ]
        : [
            AppTheme.primaryGreen.withValues(alpha: 0.4),
            AppTheme.primaryTeal.withValues(alpha: 0.4),
            Colors.purpleAccent.withValues(alpha: 0.3),
            Colors.lightBlueAccent.withValues(alpha: 0.3),
          ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background base color
        Container(
          color: widget.isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        ),
        
        // Animated Blobs
        ..._blobs.map((blob) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Calculate movement based on controller
              // Using sine waves for organic movement
              final moveX = sin(_controller.value * 2 * pi + blob.hashCode) * 0.2;
              final moveY = cos(_controller.value * 2 * pi + blob.hashCode) * 0.2;
              
              return Align(
                alignment: blob.alignment + Alignment(moveX, moveY),
                child: Container(
                  width: MediaQuery.of(context).size.width * blob.radius,
                  height: MediaQuery.of(context).size.width * blob.radius,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: blob.color,
                    // Remove blurRadius from here as per previous build fix
                    // We will use BackdropFilter for the blur effect
                  ),
                ),
              );
            },
          );
        }),

        // Strong Blur for Mesh Effect (Liquid Glass)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        
        // Glass Overlay
        Positioned.fill(
           child: Container(
             color: widget.isDark 
                 ? Colors.black.withValues(alpha: 0.3)
                 : Colors.white.withValues(alpha: 0.3),
           ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

class _BlobData {
  final Alignment alignment;
  final Color color;
  final double radius;

  _BlobData({
    required this.alignment,
    required this.color,
    required this.radius,
  });
}
