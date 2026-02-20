import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:byure/domain/entities/user_entity.dart';

/// Service for managing location services
class LocationService {
  /// Check and request location permissions
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location
  Future<LocationEntity?> getCurrentLocation() async {
    try {
      // Check if location services are enabled first
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }

      // Check current permission status
      final permissionStatus = await Permission.location.status;
      
      if (permissionStatus.isDenied) {
        // Request permission
        final hasPermission = await requestLocationPermission();
        if (!hasPermission) {
          throw Exception('Location permission is required to find nearby walkers. Please grant location permission in app settings.');
        }
      } else if (permissionStatus.isPermanentlyDenied) {
        throw Exception('Location permission is permanently denied. Please enable it in app settings.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationEntity(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Stream of location updates
  Stream<LocationEntity> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).map((position) => LocationEntity(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
        ));
  }

  /// Calculate distance between two points (in km)
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}


