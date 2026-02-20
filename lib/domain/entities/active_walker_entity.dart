import 'package:byure/domain/entities/user_entity.dart';

/// Entity representing a user who is currently available for walking
/// This is stored in a separate collection for efficient location-based queries
class ActiveWalkerEntity {
  final String userId;
  final String name;
  final int age;
  final String? photoUrl;
  final LocationEntity location;
  final String geohash;
  final WalkingPreferences walkingPreferences;
  final double availabilityRadiusKm;
  final String? currentActivity;
  final String? destinationHint;
  final DateTime lastUpdated;
  final DateTime expiresAt;
  final Gender gender;
  final GenderPreference genderPreference;
  final String? bio;
  final List<String> interests;
  final bool isPremium;

  ActiveWalkerEntity({
    required this.userId,
    required this.name,
    required this.age,
    this.photoUrl,
    required this.location,
    required this.geohash,
    required this.walkingPreferences,
    this.availabilityRadiusKm = 5.0,
    this.currentActivity,
    this.destinationHint,
    required this.lastUpdated,
    required this.expiresAt,
    required this.gender,
    required this.genderPreference,
    this.bio,
    this.interests = const [],
    this.isPremium = false,
  });

  /// Create from UserEntity
  factory ActiveWalkerEntity.fromUser({
    required UserEntity user,
    required LocationEntity location,
    required String geohash,
    double availabilityRadiusKm = 5.0,
    String? currentActivity,
    String? destinationHint,
  }) {
    final now = DateTime.now();
    return ActiveWalkerEntity(
      userId: user.id,
      name: user.name,
      age: user.age,
      photoUrl: user.photoUrls.isNotEmpty ? user.photoUrls.first : null,
      location: location,
      geohash: geohash,
      walkingPreferences: user.walkingPreferences,
      availabilityRadiusKm: availabilityRadiusKm,
      currentActivity: currentActivity,
      destinationHint: destinationHint,
      lastUpdated: now,
      expiresAt: now.add(const Duration(minutes: 15)),
      gender: user.gender,
      genderPreference: user.genderPreference,
      bio: user.bio,
      interests: user.interests,
      isPremium: user.isPremium,
    );
  }

  /// Check if this walker record has expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if this walker is still active (not expired)
  bool get isActive => !isExpired;

  /// Copy with updated fields
  ActiveWalkerEntity copyWith({
    String? userId,
    String? name,
    int? age,
    String? photoUrl,
    LocationEntity? location,
    String? geohash,
    WalkingPreferences? walkingPreferences,
    double? availabilityRadiusKm,
    String? currentActivity,
    String? destinationHint,
    DateTime? lastUpdated,
    DateTime? expiresAt,
    Gender? gender,
    GenderPreference? genderPreference,
    String? bio,
    List<String>? interests,
    bool? isPremium,
  }) {
    return ActiveWalkerEntity(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      geohash: geohash ?? this.geohash,
      walkingPreferences: walkingPreferences ?? this.walkingPreferences,
      availabilityRadiusKm: availabilityRadiusKm ?? this.availabilityRadiusKm,
      currentActivity: currentActivity ?? this.currentActivity,
      destinationHint: destinationHint ?? this.destinationHint,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expiresAt: expiresAt ?? this.expiresAt,
      gender: gender ?? this.gender,
      genderPreference: genderPreference ?? this.genderPreference,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  /// Refresh the expiration time
  ActiveWalkerEntity refreshExpiration() {
    final now = DateTime.now();
    return copyWith(
      lastUpdated: now,
      expiresAt: now.add(const Duration(minutes: 15)),
    );
  }

  /// Convert back to UserEntity (useful for UI components)
  UserEntity toUserEntity() {
    return UserEntity(
      id: userId,
      email: '', // Not stored in active_walkers for privacy
      name: name,
      age: age,
      bio: bio,
      interests: interests,
      photoUrls: photoUrl != null ? [photoUrl!] : [],
      walkingPreferences: walkingPreferences,
      isAvailableToWalk: true,
      isPremium: isPremium,
      createdAt: lastUpdated,
      safetySettings: SafetySettings(
        shareLocationWithTrustedContacts: false,
        trustedContactIds: [],
        enableSOS: true,
      ),
      gender: gender,
      genderPreference: genderPreference,
      currentLocation: location,
    );
  }
}

/// Result containing an active walker and their distance from a reference point
class ActiveWalkerWithDistance {
  final ActiveWalkerEntity walker;
  final double distanceKm;

  ActiveWalkerWithDistance({
    required this.walker,
    required this.distanceKm,
  });
}
