import 'dart:math';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/services/user_service.dart';
import 'package:uuid/uuid.dart';

class UserSeeder {
  final UserService _userService = UserService();
  final Random _random = Random();

  final List<String> _names = [
    "Alice Johnson", "Bob Smith", "Charlie Brown", "Diana Prince", "Evan Wright",
    "Fiona Gallagher", "George Miller", "Hannah Abbott", "Ian Somerhalder", "Julia Roberts"
  ];

  final List<String> _bios = [
    "Loves long walks on the beach.", "Hiking enthusiast.", "Dog lover and walker.",
    "Training for a marathon.", "Casual stroller.", "Nature photographer.",
    "Always up for a chat.", "Morning walker.", "Night owl walker.", "City explorer."
  ];

  final List<String> _interests = [
    "Hiking", "Running", "Photography", "Dogs", "Nature", "Music", "Travel", "Food", "Art", "Tech"
  ];

  Future<void> seedUsers({required double centerLat, required double centerLng, int count = 10}) async {
    for (int i = 0; i < count; i++) {
      final id = const Uuid().v4();
      final name = _names[i % _names.length];
      final bio = _bios[i % _bios.length];
      
      // Random location within ~5km
      final latOffset = (_random.nextDouble() - 0.5) * 0.09; // ~10km span
      final lngOffset = (_random.nextDouble() - 0.5) * 0.09;
      
      final user = UserEntity(
        id: id,
        email: "user$i@example.com",
        name: name,
        age: 20 + _random.nextInt(30),
        bio: bio,
        interests: [
          _interests[_random.nextInt(_interests.length)],
          _interests[_random.nextInt(_interests.length)],
        ],
        photoUrls: [
          "https://i.pravatar.cc/300?u=$id", // Placeholder avatar
        ],
        walkingPreferences: WalkingPreferences(
          pace: WalkingPace.values[_random.nextInt(WalkingPace.values.length)],
          preferredDistanceKm: 1.0 + _random.nextInt(10).toDouble(),
          preferredTerrains: const [],
          preferredTimes: const [],
        ),
        isAvailableToWalk: true,
        isPremium: _random.nextBool(),
        createdAt: DateTime.now(),
        lastSeen: DateTime.now(),
        currentLocation: LocationEntity(
          latitude: centerLat + latOffset,
          longitude: centerLng + lngOffset,
          timestamp: DateTime.now(),
        ),
        safetySettings: SafetySettings(
          shareLocationWithTrustedContacts: false,
          trustedContactIds: const [],
          enableSOS: true,
        ),
      );

      await _userService.createOrUpdateUser(user);
    }
  }
}
