
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:byure/data/models/user_model.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/services/location_service.dart';
import 'package:byure/services/active_walker_service.dart';
import 'package:byure/domain/entities/active_walker_entity.dart';

/// Service for managing user data via Supabase
class UserService {
  final _supabase = Supabase.instance.client;
  final LocationService _locationService = LocationService();
  final ActiveWalkerService _activeWalkerService = ActiveWalkerService();

  /// Get user by ID
  Future<UserEntity?> getUserById(String userId) async {
    try {
      final response = await _supabase.from('users').select().eq('id', userId).maybeSingle();
      if (response == null) return null;
      return UserModel.fromJson(response).toEntity();
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Create or update user profile
  Future<void> createOrUpdateUser(UserEntity user) async {
    try {
      final model = UserModel.fromEntity(user);
      // upsert: conflict on 'id'
      await _supabase.from('users').upsert(model.toJson());
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  /// Alias for createOrUpdateUser
  Future<void> updateUser(UserEntity user) async {
    await createOrUpdateUser(user);
    
    // Propagate updates to active walker if necessary.
    // In Supabase, we JOIN active_walkers with users, so we don't strictly NEED 
    // to denormalize name/photo into active_walkers.
    // However, if the active walker table relies on 'is_premium' for coloring logic, sync that.
    // Our RPC 'upsert_active_walker' takes 'is_prem'.
    /*
    final isActive = await _activeWalkerService.isUserActiveWalker(user.id);
    if (isActive) {
       // Refresh just to sync premium status or other fields if we denormalized any
    }
    */
  }

  /// Update user location (Profile only, different from Active Walker)
  Future<void> updateUserLocation(String userId) async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        await _supabase.from('users').update({
          'current_location': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'last_seen': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      }
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  /// Get nearby users (Non-Active Discovery)
  /// Note: 'users' table doesn't have PostGIS index usually unless we add it.
  /// For now, we fallback to non-geo or just return recent users.
  Future<List<UserEntity>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
  }) async {
      // In this app, "Nearby Users" usually means Active Walkers.
      // If we mean ALL users, we need a PostGIS column on 'users' table too.
      // Our generic Active Walker RPC is better.
      // Returning just recent users for now if this method is used for generic friendship.
      
      final response = await _supabase.from('users')
          .select()
          .limit(limit);
          
      return (response as List).map((e) => UserModel.fromJson(e).toEntity()).toList();
  }

  /// Toggle user's walking availability
  Future<void> toggleWalkingAvailability({
    required String userId,
    required bool isAvailable,
    double availabilityRadiusKm = 5.0,
    String? currentActivity,
    String? destinationHint,
  }) async {
    try {
      // Logic: Setup Active Walker record
      if (isAvailable) {
        final location = await _locationService.getCurrentLocation();
        if (location == null) throw Exception('Unable to get current location');

        final user = await getUserById(userId);
        if (user == null) throw Exception('User not found');

        await _activeWalkerService.setActiveWalker(
          user: user,
          location: location,
          availabilityRadiusKm: availabilityRadiusKm,
          currentActivity: currentActivity,
          destinationHint: destinationHint,
        );
      } else {
        await _activeWalkerService.removeActiveWalker(userId);
      }
      
      // We don't necessarily update 'isAvailableToWalk' boolean in users table 
      // because presence in active_walkers table IS the truth.
    } catch (e) {
      throw Exception('Failed to toggle walking availability: $e');
    }
  }

  /// Update location for both user profile and active walker (if active)
  Future<void> updateLocationForWalking(String userId) async {
    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) throw Exception('Unable to get current location');

      // Update basic profile location
      await updateUserLocation(userId);

      // Update active walker if active
      final isActive = await _activeWalkerService.isUserActiveWalker(userId);
      if (isActive) {
        await _activeWalkerService.updateActiveWalkerLocation(
          userId: userId,
          location: location,
        );
      }
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  /// Get nearby active walkers for a user (Filtered by Preference)
  Future<List<ActiveWalkerWithDistance>> getNearbyWalkersForUser({
    required String userId,
    required double radiusKm,
    LocationEntity? currentLocation,
    int limit = 50,
  }) async {
    try {
      final user = await getUserById(userId);
      double lat, long;

      if (currentLocation != null) {
        lat = currentLocation.latitude;
        long = currentLocation.longitude;
      } else if (user?.currentLocation != null) {
        lat = user!.currentLocation!.latitude;
        long = user.currentLocation!.longitude;
      } else {
        // Fallback to simpler query if no location known?
         // Or getting location from service
         final loc = await _locationService.getCurrentLocation();
         if (loc == null) return [];
         lat = loc.latitude;
         long = loc.longitude;
      }
      
      final nearbyWalkers = await _activeWalkerService.getNearbyWalkers(
        latitude: lat,
        longitude: long,
        radiusKm: radiusKm,
        excludeUserId: userId,
        limit: limit * 2,
      );

      // Fetch IDs of users already swiped by this user
      final swipedResponse = await _supabase
          .from('swipes')
          .select('target_id')
          .eq('liker_id', userId);
      
      final swipedIds = (swipedResponse as List).map((e) => e['target_id'] as String).toSet();

      if (user != null) {
           return nearbyWalkers.where((start) {
             if (swipedIds.contains(start.walker.userId)) return false;
             return _isMatch(user, start.walker);
           }).take(limit).toList();
      }
      return nearbyWalkers.where((w) => !swipedIds.contains(w.walker.userId)).take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get nearby walkers: $e');
    }
  }

  /// Stream nearby walkers for real-time updates (Filtered by Preference)
  Stream<List<ActiveWalkerWithDistance>> streamNearbyWalkersForUser({
    required String userId,
    required double latitude,
    required double longitude,
    required double radiusKm,
    int limit = 50,
  }) {
    // We defer to the polling stream in ActiveWalkerService
    return _activeWalkerService.streamNearbyWalkers(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      excludeUserId: userId,
      limit: limit * 2,
    ).asyncMap((walkers) async {
       try {
         final user = await getUserById(userId);
         if (user == null) return walkers; // Or empty?

         return walkers.where((w) {
           return _isMatch(user, w.walker);
         }).take(limit).toList();
       } catch (e) {
         return [];
       }
    });
  }

  /// Strict Matching Algorithm
  bool _isMatch(UserEntity me, ActiveWalkerEntity walker) {
     bool matchesMyPref = false;
     if (me.genderPreference == GenderPreference.both) {
       matchesMyPref = true; // "I match with anyone"
     } else if (me.genderPreference == GenderPreference.men && walker.gender == Gender.male) {
       matchesMyPref = true;
     } else if (me.genderPreference == GenderPreference.women && walker.gender == Gender.female) {
       matchesMyPref = true;
     }

     bool matchesWalkerPref = false;
     // Note: Walker's preference is critical too.
     if (walker.genderPreference == GenderPreference.both) {
       matchesWalkerPref = true; // "They match with anyone"
     } else if (walker.genderPreference == GenderPreference.men && me.gender == Gender.male) {
       matchesWalkerPref = true;
     } else if (walker.genderPreference == GenderPreference.women && me.gender == Gender.female) {
       matchesWalkerPref = true;
     }

     return matchesMyPref && matchesWalkerPref;
  }
}



