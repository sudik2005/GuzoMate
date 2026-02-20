import 'package:byure/domain/entities/active_walker_entity.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/data/models/user_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Used only for types if needed, but mainly Map

/// Supabase model for active walker data
class ActiveWalkerModel {
  final String userId;
  final double latitude;
  final double longitude;
  final String? destinationHint;
  final DateTime lastUpdated;
  final DateTime expiresAt;
  final bool isPremium;
  
  // User Data (Joined)
  final UserModel? user;

  ActiveWalkerModel({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.destinationHint,
    required this.lastUpdated,
    required this.expiresAt,
    this.isPremium = false,
    this.user,
  });

  /// Create from Supabase RPC response (which includes joined user_data)
  factory ActiveWalkerModel.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    double long = 0.0;
    
    // 1. Direct lat/long (RPC results)
    if (json.containsKey('lat') && json.containsKey('long')) {
      lat = (json['lat'] as num).toDouble();
      long = (json['long'] as num).toDouble();
    } 
    // 2. PostGIS location column (Table stream/select)
    // Supabase returns PostGIS geography as a GeoJSON object or WKB string
    else if (json.containsKey('location')) {
      final loc = json['location'];
      if (loc is Map<String, dynamic> && loc.containsKey('coordinates')) {
        // GeoJSON: { "type": "Point", "coordinates": [longitude, latitude] }
        final coords = loc['coordinates'] as List<dynamic>;
        long = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      } else if (loc is String) {
        // WKT: POINT(long lat) - Very basic parsing
        try {
          final clean = loc.replaceAll('POINT(', '').replaceAll(')', '').trim();
          final parts = clean.split(' ');
          long = double.parse(parts[0]);
          lat = double.parse(parts[1]);
        } catch (_) {}
      }
    }
    
    return ActiveWalkerModel(
      userId: json['user_id'] as String,
      latitude: lat,
      longitude: long,
      destinationHint: json['destination_hint'] as String?,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isPremium: json['is_premium'] as bool? ?? false,
      user: json['user_data'] != null ? UserModel.fromJson(json['user_data']) : null,
    );
  }

  /// Convert to entity
  ActiveWalkerEntity toEntity({UserEntity? fallbackUser}) {
    final userEntity = user?.toEntity() ?? fallbackUser;
    
    if (userEntity == null) {
      throw Exception("ActiveWalkerModel requires joined user data or a fallback UserEntity");
    }

    return ActiveWalkerEntity(
      userId: userId,
      name: userEntity.name,
      age: userEntity.age,
      // UserEntity has List<String> photoUrls, not photoUrl
      photoUrl: userEntity.photoUrls.isNotEmpty ? userEntity.photoUrls.first : null,
      location: LocationEntity(
        latitude: latitude,
        longitude: longitude,
        timestamp: lastUpdated,
      ),
      geohash: '', // Not used with PostGIS
      walkingPreferences: userEntity.walkingPreferences,
      availabilityRadiusKm: 5.0, // Default or fetch from user prefs if stored
      currentActivity: null,
      destinationHint: destinationHint,
      lastUpdated: lastUpdated,
      expiresAt: expiresAt,
      gender: userEntity.gender,
      genderPreference: userEntity.genderPreference,
      bio: userEntity.bio,
      interests: userEntity.interests,
      isPremium: isPremium,
    );
  }
}

