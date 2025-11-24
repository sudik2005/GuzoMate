import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:byure/data/models/user_model.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/services/location_service.dart';

/// Service for managing user data
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  /// Get user by ID
  Future<UserEntity?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc).toEntity();
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Create or update user profile
  Future<void> createOrUpdateUser(UserEntity user) async {
    try {
      final model = UserModel.fromEntity(user);
      await _firestore.collection('users').doc(user.id).set(
            model.toFirestore(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  /// Update user location
  Future<void> updateUserLocation(String userId) async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        await _firestore.collection('users').doc(userId).update({
          'currentLocation': {
            'latitude': location.latitude,
            'longitude': location.longitude,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  /// Get nearby users
  Future<List<UserEntity>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
  }) async {
    try {
      // Note: Firestore doesn't support native geoqueries
      // In production, use GeoFirestore or similar solution
      // This is a simplified version that fetches all available users
      // and filters client-side (not recommended for large datasets)
      
      final snapshot = await _firestore
          .collection('users')
          .where('isAvailableToWalk', isEqualTo: true)
          .limit(limit)
          .get();

      final users = <UserEntity>[];
      for (var doc in snapshot.docs) {
        final user = UserModel.fromFirestore(doc).toEntity();
        if (user.currentLocation != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            user.currentLocation!.latitude,
            user.currentLocation!.longitude,
          );
          if (distance <= radiusKm) {
            users.add(user);
          }
        }
      }
      return users;
    } catch (e) {
      throw Exception('Failed to get nearby users: $e');
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}


