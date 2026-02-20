import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:byure/services/location_service.dart';
import 'package:byure/services/active_walker_service.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/domain/entities/active_walker_entity.dart';
import 'package:byure/presentation/providers/auth_provider.dart';
import 'package:byure/core/theme/app_theme.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final UserEntity buddy;

  const LiveTrackingScreen({super.key, required this.buddy});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final ActiveWalkerService _activeWalkerService = ActiveWalkerService();
  
  StreamSubscription<LocationEntity>? _locationSubscription;
  LatLng? _userLocation;
  LatLng? _buddyLocation;
  double _distanceKm = 0.0;
  String _eta = "Calculating...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initTracking();
  }

  Future<void> _initTracking() async {
    // 1. Get initial user location
    final loc = await _locationService.getCurrentLocation();
    if (loc != null) {
      if (mounted) {
        setState(() {
          _userLocation = LatLng(loc.latitude, loc.longitude);
        });
      }
    }

    // 2. Start streaming user location (to update backend)
    _locationSubscription = _locationService.getLocationStream().listen((loc) {
      if (mounted) {
        final newLoc = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _userLocation = newLoc;
          _updateDistanceAndETA();
        });
        
        // Update visibility on map if they are an active walker
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
          // We can call service to update location
          // _activeWalkerService.updateActiveWalkerLocation(userId: currentUser.id, location: loc);
        }
      }
    });

    setState(() => _isLoading = false);
  }

  void _updateDistanceAndETA() {
    if (_userLocation != null && _buddyLocation != null) {
      const Distance distance = Distance();
      final double meters = distance.as(
        LengthUnit.Meter,
        _userLocation!,
        _buddyLocation!,
      );
      
      _distanceKm = meters / 1000.0;
      _eta = _activeWalkerService.calculateETA(_distanceKm);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Walking with ${widget.buddy.name}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // THE MAP
          StreamBuilder<ActiveWalkerEntity?>(
            stream: _activeWalkerService.streamBuddyLocation(widget.buddy.id, buddyUser: widget.buddy),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final walker = snapshot.data!;
                _buddyLocation = LatLng(walker.location.latitude, walker.location.longitude);
                // Update local state for ETA calc
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _updateDistanceAndETA();
                });
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation ?? const LatLng(0, 0),
                  initialZoom: 15.0,
                  minZoom: 3.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate, 
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.byure',
                  ),
                  MarkerLayer(
                    markers: [
                      // User Marker
                      if (_userLocation != null)
                        Marker(
                          point: _userLocation!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                        ),
                      // Buddy Marker
                      if (_buddyLocation != null)
                        Marker(
                          point: _buddyLocation!,
                          width: 60,
                          height: 60,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundImage: widget.buddy.photoUrls.isNotEmpty
                                      ? NetworkImage(widget.buddy.photoUrls.first)
                                      : null,
                                  child: widget.buddy.photoUrls.isEmpty
                                      ? Text(widget.buddy.name[0])
                                      : null,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: AppTheme.primaryGreen),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),

          // Bottom Info Panel (Uber style)
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey[900] 
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _eta,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            Text(
                              '${_distanceKm.toStringAsFixed(1)} km away',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  Row(
                    children: [
                      const Icon(Icons.security, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Meeting in a public place? Stay safe!',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Emergency SOS or share location
                        },
                        child: const Text('Share Trip'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
