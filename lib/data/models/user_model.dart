import 'package:byure/domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final int age;
  final String? bio;
  final List<String> interests;
  final List<String> photoUrls;
  final Map<String, dynamic> walkingPreferences;
  final bool isAvailableToWalk; // Note: In Supabase, this is derived from active_walkers table, but we can keep it if synced
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? lastSeen; // Unused in Supabase mostly
  final Map<String, dynamic>? currentLocation;
  final Map<String, dynamic> safetySettings;
  final String gender;
  final String genderPreference;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    this.bio,
    required this.interests,
    required this.photoUrls,
    required this.walkingPreferences,
    this.isAvailableToWalk = false,
    required this.isPremium,
    required this.createdAt,
    this.lastSeen,
    this.currentLocation,
    required this.safetySettings,
    required this.gender,
    required this.genderPreference,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 18,
      bio: json['bio'],
      interests: List<String>.from(json['interests'] != null 
          ? (json['interests'] is List ? json['interests'] : []) 
          : []), // Supabase can return null
      // Handle legacy 'photo_url' vs 'photo_urls'
      photoUrls: json['photo_urls'] != null 
          ? List<String>.from(json['photo_urls'])
          : (json['photo_url'] != null ? [json['photo_url']] : []),
      walkingPreferences: json['walking_preferences'] ?? {},
      isAvailableToWalk: false, // Calculated field, not in users table directly usually
      isPremium: json['is_premium'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      currentLocation: json['current_location'],
      safetySettings: json['safety_settings'] ?? {},
      gender: json['gender'] ?? 'male',
      genderPreference: json['gender_preference'] ?? 'women',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Usually ignored in insert if auto-generated, but needed for reference
      'email': email,
      'name': name,
      'age': age,
      'bio': bio,
      'interests': interests, // Supabase handles list -> array
      'photo_urls': photoUrls,
      'walking_preferences': walkingPreferences,
      'is_premium': isPremium,
      // 'created_at': createdAt.toIso8601String(), // Usually ready-only or auto
      'last_seen': lastSeen?.toIso8601String(),
      'current_location': currentLocation,
      'safety_settings': safetySettings,
      'gender': gender,
      'gender_preference': genderPreference,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      age: age,
      bio: bio,
      interests: interests,
      photoUrls: photoUrls,
      walkingPreferences: _parseWalkingPreferences(walkingPreferences),
      isAvailableToWalk: isAvailableToWalk,
      isPremium: isPremium,
      createdAt: createdAt,
      lastSeen: lastSeen,
      currentLocation: currentLocation != null
          ? LocationEntity(
              latitude: (currentLocation!['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude: (currentLocation!['longitude'] as num?)?.toDouble() ?? 0.0,
              timestamp: DateTime.now(), // timestamp might be missing in simple json
            )
          : null,
      safetySettings: SafetySettings(
        shareLocationWithTrustedContacts:
            safetySettings['shareLocationWithTrustedContacts'] ?? false,
        trustedContactIds: List<String>.from(safetySettings['trustedContactIds'] ?? []),
        enableSOS: safetySettings['enableSOS'] ?? true,
      ),
      gender: Gender.values.firstWhere(
        (e) => e.name == gender,
        orElse: () => Gender.male,
      ),
      genderPreference: GenderPreference.values.firstWhere(
        (e) => e.name == genderPreference,
        orElse: () => GenderPreference.women,
      ),
    );
  }

  WalkingPreferences _parseWalkingPreferences(Map<String, dynamic> prefs) {
    return WalkingPreferences(
      pace: WalkingPace.values.firstWhere(
        (p) => p.name == prefs['pace'],
        orElse: () => WalkingPace.moderate,
      ),
      preferredDistanceKm: (prefs['preferredDistanceKm'] as num? ?? 5.0).toDouble(),
      searchRadiusKm: (prefs['searchRadiusKm'] as num? ?? 10.0).toDouble(),
      preferredTerrains: (prefs['preferredTerrains'] as List<dynamic>?)
              ?.map((t) => TerrainType.values.firstWhere(
                    (tt) => tt.name == t,
                    orElse: () => TerrainType.urban,
                  ))
              .toList() ??
          [],
      preferredTimes: List<String>.from(prefs['preferredTimes'] ?? []),
    );
  }

  static UserModel fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      age: entity.age,
      bio: entity.bio,
      interests: entity.interests,
      photoUrls: entity.photoUrls,
      walkingPreferences: {
        'pace': entity.walkingPreferences.pace.name,
        'preferredDistanceKm': entity.walkingPreferences.preferredDistanceKm,
        'searchRadiusKm': entity.walkingPreferences.searchRadiusKm,
        'preferredTerrains': entity.walkingPreferences.preferredTerrains.map((t) => t.name).toList(),
        'preferredTimes': entity.walkingPreferences.preferredTimes,
      },
      isAvailableToWalk: entity.isAvailableToWalk,
      isPremium: entity.isPremium,
      createdAt: entity.createdAt,
      lastSeen: entity.lastSeen,
      currentLocation: entity.currentLocation != null
          ? {
              'latitude': entity.currentLocation!.latitude,
              'longitude': entity.currentLocation!.longitude,
            }
          : null,
      safetySettings: {
        'shareLocationWithTrustedContacts': entity.safetySettings.shareLocationWithTrustedContacts,
        'trustedContactIds': entity.safetySettings.trustedContactIds,
        'enableSOS': entity.safetySettings.enableSOS,
      },
      gender: entity.gender.name,
      genderPreference: entity.genderPreference.name,
    );
  }
}
