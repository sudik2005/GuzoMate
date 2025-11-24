import 'package:cloud_firestore/cloud_firestore.dart';
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
  final bool isAvailableToWalk;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final Map<String, dynamic>? currentLocation;
  final Map<String, dynamic> safetySettings;

  UserModel({
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

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      bio: data['bio'],
      interests: List<String>.from(data['interests'] ?? []),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      walkingPreferences: Map<String, dynamic>.from(data['walkingPreferences'] ?? {}),
      isAvailableToWalk: data['isAvailableToWalk'] ?? false,
      isPremium: data['isPremium'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      currentLocation: data['currentLocation'] != null
          ? Map<String, dynamic>.from(data['currentLocation'])
          : null,
      safetySettings: Map<String, dynamic>.from(data['safetySettings'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'age': age,
      'bio': bio,
      'interests': interests,
      'photoUrls': photoUrls,
      'walkingPreferences': walkingPreferences,
      'isAvailableToWalk': isAvailableToWalk,
      'isPremium': isPremium,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'currentLocation': currentLocation,
      'safetySettings': safetySettings,
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
              latitude: currentLocation!['latitude'] ?? 0.0,
              longitude: currentLocation!['longitude'] ?? 0.0,
              timestamp: (currentLocation!['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            )
          : null,
      safetySettings: SafetySettings(
        shareLocationWithTrustedContacts:
            safetySettings['shareLocationWithTrustedContacts'] ?? false,
        trustedContactIds: List<String>.from(safetySettings['trustedContactIds'] ?? []),
        enableSOS: safetySettings['enableSOS'] ?? true,
      ),
    );
  }

  WalkingPreferences _parseWalkingPreferences(Map<String, dynamic> prefs) {
    return WalkingPreferences(
      pace: WalkingPace.values.firstWhere(
        (p) => p.name == prefs['pace'],
        orElse: () => WalkingPace.moderate,
      ),
      preferredDistanceKm: (prefs['preferredDistanceKm'] ?? 5.0).toDouble(),
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
              'timestamp': Timestamp.fromDate(entity.currentLocation!.timestamp),
            }
          : null,
      safetySettings: {
        'shareLocationWithTrustedContacts': entity.safetySettings.shareLocationWithTrustedContacts,
        'trustedContactIds': entity.safetySettings.trustedContactIds,
        'enableSOS': entity.safetySettings.enableSOS,
      },
    );
  }
}


