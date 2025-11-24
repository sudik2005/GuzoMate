/// User entity representing a GuzoMate user
class UserEntity {
  final String id;
  final String email;
  final String name;
  final int age;
  final String? bio;
  final List<String> interests;
  final List<String> photoUrls;
  final WalkingPreferences walkingPreferences;
  final bool isAvailableToWalk;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final LocationEntity? currentLocation;
  final SafetySettings safetySettings;

  UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    this.bio,
    required this.interests,
    required this.photoUrls,
    required this.walkingPreferences,
    required this.isAvailableToWalk,
    required this.isPremium,
    required this.createdAt,
    this.lastSeen,
    this.currentLocation,
    required this.safetySettings,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? bio,
    List<String>? interests,
    List<String>? photoUrls,
    WalkingPreferences? walkingPreferences,
    bool? isAvailableToWalk,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? lastSeen,
    LocationEntity? currentLocation,
    SafetySettings? safetySettings,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      photoUrls: photoUrls ?? this.photoUrls,
      walkingPreferences: walkingPreferences ?? this.walkingPreferences,
      isAvailableToWalk: isAvailableToWalk ?? this.isAvailableToWalk,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      currentLocation: currentLocation ?? this.currentLocation,
      safetySettings: safetySettings ?? this.safetySettings,
    );
  }
}

/// Walking preferences for a user
class WalkingPreferences {
  final WalkingPace pace;
  final double preferredDistanceKm;
  final List<TerrainType> preferredTerrains;
  final List<String> preferredTimes; // e.g., ["morning", "evening"]

  WalkingPreferences({
    required this.pace,
    required this.preferredDistanceKm,
    required this.preferredTerrains,
    required this.preferredTimes,
  });
}

enum WalkingPace {
  slow, // < 4 km/h
  moderate, // 4-6 km/h
  fast, // > 6 km/h
}

enum TerrainType {
  urban,
  park,
  trail,
  beach,
  mountain,
}

/// Location entity
class LocationEntity {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationEntity({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

/// Safety settings
class SafetySettings {
  final bool shareLocationWithTrustedContacts;
  final List<String> trustedContactIds;
  final bool enableSOS;

  SafetySettings({
    required this.shareLocationWithTrustedContacts,
    required this.trustedContactIds,
    required this.enableSOS,
  });
}

