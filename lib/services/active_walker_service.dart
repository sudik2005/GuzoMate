import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:byure/domain/entities/active_walker_entity.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/data/models/active_walker_model.dart';


/// Service for managing active walker data and location-based queries via Supabase PostGIS
class ActiveWalkerService {
  final _supabase = Supabase.instance.client;


  /// Create or update an active walker record
  /// This makes the user visible to others for walking
  Future<void> setActiveWalker({
    required UserEntity user,
    required LocationEntity location,
    double availabilityRadiusKm = 5.0,
    String? currentActivity,
    String? destinationHint,
  }) async {
    try {
      // Use the upsert_active_walker RPC for simplicity in handling PostGIS
      await _supabase.rpc('upsert_active_walker', params: {
        'lon': location.longitude,
        'lat': location.latitude,
        'dest_hint': destinationHint ?? '',
        'is_prem': user.isPremium
      });
    } catch (e) {
      throw Exception('Failed to set active walker: $e');
    }
  }

  /// Update location for an active walker
  /// This refreshes the expiration time and updates the position
  Future<void> updateActiveWalkerLocation({
    required String userId,
    required LocationEntity location,
  }) async {
    try {
      await _supabase.rpc('upsert_active_walker', params: {
        'lon': location.longitude,
        'lat': location.latitude,
        // Keep payload valid for RPC while preserving existing destination hint/premium status.
        'dest_hint': '',
        'is_prem': false,
      });
    } catch (e) {
      throw Exception('Failed to update active walker location: $e');
    }
  }

  /// Remove a user from active walkers
  Future<void> removeActiveWalker(String userId) async {
    try {
      await _supabase.from('active_walkers').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove active walker: $e');
    }
  }

  /// Get nearby active walkers within a radius
  Future<List<ActiveWalkerWithDistance>> getNearbyWalkers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? excludeUserId,
    int limit = 50,
  }) async {
    try {
      final response = await _supabase.rpc('get_nearby_walkers', params: {
        'p_lat': latitude,
        'p_long': longitude,
        'p_radius_meters': radiusKm * 1000,
      });

      final List<dynamic> data = response as List<dynamic>;
      final results = <ActiveWalkerWithDistance>[];

      for (final item in data) {
        try {
          // Parse using our updated Model which handles RPC structure
          final walkerModel = ActiveWalkerModel.fromJson(item as Map<String, dynamic>);
          
          if (excludeUserId != null && walkerModel.userId == excludeUserId) {
            continue;
          }

          // Convert to Entity
          final entity = walkerModel.toEntity();
          
          // Distance (RPC returns it in meters, but we can verify or use it)
          // Model doesn't store distance, so we calculate or use RPC val
          double distance = (item['distance_meters'] as num).toDouble() / 1000.0; 

          // Filter out invalid coordinates (0,0 usually defaults for errors)
          if (entity.location.latitude == 0.0 && entity.location.longitude == 0.0) {
            continue;
          }

          results.add(ActiveWalkerWithDistance(
            walker: entity,
            distanceKm: distance,
          ));
        } catch (e) {
          // debugPrint('Error parsing walker: $e');
        }
      }

      return results;
    } catch (e) {
      throw Exception('Failed to get nearby walkers: $e');
    }
  }

  /// Stream of nearby active walkers
  /// Supabase Realtime doesn't support complex PostGIS filters easily.
  /// Standard pattern: Poll or Realtime on entire table + Client filter (inefficient) OR just Poll.
  /// Since location updates every few minutes, **Polling** the RPC is actually efficiently fine and supports the Radius filter.
  Stream<List<ActiveWalkerWithDistance>> streamNearbyWalkers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? excludeUserId,
    int limit = 50,
  }) {
    // Poll every 10 seconds for discovery (PostGIS query)
    return Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => getNearbyWalkers(
              latitude: latitude,
              longitude: longitude,
              radiusKm: radiusKm,
              excludeUserId: excludeUserId,
              limit: limit,
            ))
        .asBroadcastStream();
  }

  /// Real-time stream for a specific buddy's location
  /// Used for the Uber-style tracking view
  Stream<ActiveWalkerEntity?> streamBuddyLocation(String buddyId, {UserEntity? buddyUser}) {
    return _supabase
        .from('active_walkers')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', buddyId)
        .map((data) {
          if (data.isEmpty) return null;
          
          final item = data.first;
          // Note: .stream() doesn't support complex joins like .select('*, users(*)')
          // So we use the fallback user to convert to Entity
          return ActiveWalkerModel.fromJson(item).toEntity(fallbackUser: buddyUser);
        });
  }

  /// Simple ETA calculation based on average walking speed (5 km/h)
  String calculateETA(double distanceKm) {
    if (distanceKm < 0.05) return "Arrived";
    
    // 5 km / 60 mins = 0.0833 km per minute
    final minutes = (distanceKm / 0.0833).ceil();
    
    if (minutes < 1) return "< 1 min";
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMins = minutes % 60;
      return "${hours}h ${remainingMins}m";
    }
    return "$minutes mins";
  }

  /// Get a specific active walker by user ID
  Future<ActiveWalkerEntity?> getActiveWalker(String userId) async {
    try {
      // We need to join with users to get full data
      final response = await _supabase
          .from('active_walkers')
          .select('*, users(*)') // Relations!
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      // Map Supabase response to structure expected by Model
      // The select('*, users(*)') returns user data nested in 'users'
      // Our Model expects 'user_data' key for the join or flat structure?
      // Model.fromJson expects 'user_data' (from RPC) OR we adapt it.
      // Let's normalize the data map to match what Model.fromJson expects
      
      final data = Map<String, dynamic>.from(response);
      data['user_data'] = data['users']; // Remap 'users' relation to 'user_data'
      
      final model = ActiveWalkerModel.fromJson(data);
      if (model.expiresAt.isBefore(DateTime.now())) return null;
      
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to get active walker: $e');
    }
  }

  /// Check if a user is currently an active walker
  Future<bool> isUserActiveWalker(String userId) async {
    final walker = await getActiveWalker(userId);
    return walker != null;
  }
  
  /// Refresh the expiration time
  Future<void> refreshActiveWalker(String userId) async {
     // Just update timestamps
     await _supabase.from('active_walkers').update({
       'last_updated': DateTime.now().toIso8601String(),
       'expires_at': DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
     }).eq('user_id', userId);
  }

  /// Clean up expired walkers 
  /// (Best done via Database Cron/Edge Function, but kept for compatibility)
  Future<int> cleanupExpiredWalkers() async {
    // Supabase RLS usually prevents users from deleting others. 
    // This function likely won't work client-side unless Admin.
    // We rely on 'get_nearby_walkers' filtering them out.
    return 0;
  }
}

