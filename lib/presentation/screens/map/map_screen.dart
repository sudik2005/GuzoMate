import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:byure/services/location_service.dart';
import 'package:byure/services/user_service.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/presentation/widgets/walker_marker_info_window.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  List<UserEntity> _nearbyUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _currentLocation = LatLng(location.latitude, location.longitude);
      });
      await _loadNearbyUsers();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadNearbyUsers() async {
    if (_currentLocation == null) return;

    try {
      final users = await _userService.getNearbyUsers(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radiusKm: 10.0, // 10km radius
      );

      setState(() {
        _nearbyUsers = users;
        _markers = _buildMarkers(users);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load nearby users: $e')),
        );
      }
    }
  }

  Set<Marker> _buildMarkers(List<UserEntity> users) {
    return users.map((user) {
      if (user.currentLocation == null) return null;
      
      return Marker(
        markerId: MarkerId(user.id),
        position: LatLng(
          user.currentLocation!.latitude,
          user.currentLocation!.longitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          user.isAvailableToWalk
              ? BitmapDescriptor.hueGreen
              : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: user.name,
          snippet: user.isAvailableToWalk ? 'Available to walk' : 'Not available',
        ),
        onTap: () {
          _showUserDetails(user);
        },
      );
    }).whereType<Marker>().toSet();
  }

  void _showUserDetails(UserEntity user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WalkerMarkerInfoWindow(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentLocation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nearby Walkers'),
        ),
        body: const Center(
          child: Text('Unable to get your location'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Walkers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter dialog
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyUsers,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 13,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
          ),
          // Floating action button for current location
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () async {
                final location = await _locationService.getCurrentLocation();
                if (location != null && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(location.latitude, location.longitude),
                    ),
                  );
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}


