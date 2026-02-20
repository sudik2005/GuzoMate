import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:byure/services/location_service.dart';
import 'package:byure/services/user_service.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/domain/entities/active_walker_entity.dart';
import 'package:byure/presentation/providers/auth_provider.dart'; // Added import

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  
  // Animation for pulsing location marker
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription<LocationEntity>? _locationSubscription;
  LatLng? _currentLocation;
  List<Marker> _markers = [];
  List<ActiveWalkerWithDistance> _nearbyWalkers = [];
  bool _isLoading = true;
  bool _isAvailableToWalk = false;

  @override
  void initState() {
    super.initState();
    _setupPulseAnimation();
    _initializeMap();
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      // get initial location
      final location = await _locationService.getCurrentLocation();
      
      if (location != null) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(location.latitude, location.longitude);
            _isLoading = false;
          });
          
          await _loadNearbyWalkers();
          
          // Start streaming location
          _startLocationStream();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error getting location: $e');
      }
    }
  }

  void _startLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.getLocationStream().listen((location) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(location.latitude, location.longitude);
          // Rebuild markers with new location
          _markers = _buildMarkers(_nearbyWalkers);
        });

        // Sync to backend if online
        if (_isAvailableToWalk) {
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            _userService.updateLocationForWalking(currentUser.id);
          }
        }
      }
    }, onError: (e) {
      debugPrint('Location stream error: $e');
    });
  }

  Future<void> _loadNearbyWalkers() async {
    if (_currentLocation == null) return;

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;
      
      final user = await _userService.getUserById(currentUser.id);
      final radius = user?.walkingPreferences.searchRadiusKm ?? 10.0;
      
      final walkers = await _userService.getNearbyWalkersForUser(
        userId: currentUser.id,
        radiusKm: radius,
      );

      if (mounted) {
        setState(() {
          _nearbyWalkers = walkers;
          _markers = _buildMarkers(walkers);
        });
      }
    } catch (e) {
      debugPrint('Error loading walkers: $e');
    }
  }

  List<Marker> _buildMarkers(List<ActiveWalkerWithDistance> walkers) {
    if (_currentLocation == null) return [];

    final markers = <Marker>[];

    // Nearby walkers markers (Add first so they are behind user location)
    for (var walkerWithDistance in walkers) {
      final walker = walkerWithDistance.walker;
      markers.add(
        Marker(
          point: LatLng(walker.location.latitude, walker.location.longitude),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _showWalkerDetails(walkerWithDistance),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 2),
                image: walker.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(walker.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: walker.photoUrl == null
                  ? Center(
                      child: Text(
                        walker.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      );
    }

    // Current user marker (Add last to be on top)
    markers.add(
      Marker(
        point: _currentLocation!,
        width: 80,
        height: 80,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Pulse effect
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_isAvailableToWalk ? Colors.green : Colors.blue).withOpacity(0.3),
                    ),
                  ),
                ),
                // Solid dot
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _isAvailableToWalk ? Colors.green : Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    
    return markers;
  }

  void _showWalkerDetails(ActiveWalkerWithDistance walkerWithDistance) {
    final walker = walkerWithDistance.walker;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: walker.photoUrl != null
                      ? NetworkImage(walker.photoUrl!)
                      : null,
                  child: walker.photoUrl == null
                      ? Text(walker.name[0])
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        walker.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${walker.age} years old'),
                      Text(
                        '${walkerWithDistance.distanceKm.toStringAsFixed(2)} km away',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (walker.currentActivity != null) ...[
              const Text(
                'Current Activity',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(walker.currentActivity!),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Send walk invite
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Invite to Walk'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for auth changes to reload walkers if they were missed on start
    ref.listen(currentUserProvider, (previous, next) {
      if (previous == null && next != null) {
        _loadNearbyWalkers();
      }
    });

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nearby Walkers')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Unable to get location'),
              TextButton(
                onPressed: _initializeMap,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Walkers'),
        actions: [
          IconButton(
            icon: Icon(_isAvailableToWalk ? Icons.visibility : Icons.visibility_off),
            color: _isAvailableToWalk ? Colors.green : Colors.grey,
            onPressed: () async {
              try {
                final currentUser = ref.read(currentUserProvider);
                if (currentUser == null) return;

                await _userService.toggleWalkingAvailability(
                  userId: currentUser.id,
                  isAvailable: !_isAvailableToWalk,
                );
                setState(() => _isAvailableToWalk = !_isAvailableToWalk);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isAvailableToWalk
                          ? 'You are visible to others'
                          : 'You are hidden'),
                      backgroundColor: _isAvailableToWalk ? Colors.green : Colors.grey,
                    ),
                  );
                }
              } catch (e) {
                // Handle error
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyWalkers,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 15.0,
              minZoom: 4.0, // Prevents zooming out to see repeated worlds
              interactionOptions: const InteractionOptions(
                 flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.byure',
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          
          // Floating action button for current location
          Positioned(
            right: 16,
            bottom: 120, // Raised to avoid custom bottom navigation bar
            child: FloatingActionButton(
              onPressed: () {
                if (_currentLocation != null) {
                  _mapController.move(_currentLocation!, 15.0);
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


