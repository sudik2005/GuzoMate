import 'package:byure/domain/entities/user_entity.dart';

/// Walk invitation entity
class WalkInviteEntity {
  final String id;
  final String fromUserId;
  final String toUserId;
  final RouteEntity? suggestedRoute;
  final DateTime scheduledTime;
  final String meetingLocation;
  final double? estimatedDistanceKm;
  final WalkInviteStatus status;
  final String? message;
  final DateTime createdAt;
  final UserEntity? fromUser; // Populated when fetching invites

  WalkInviteEntity({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.suggestedRoute,
    required this.scheduledTime,
    required this.meetingLocation,
    this.estimatedDistanceKm,
    required this.status,
    this.message,
    required this.createdAt,
    this.fromUser,
  });
}

enum WalkInviteStatus {
  pending,
  accepted,
  declined,
  cancelled,
  completed,
}

/// Route entity for walking routes
class RouteEntity {
  final String id;
  final String name;
  final String? description;
  final List<LocationEntity> waypoints;
  final double distanceKm;
  final double estimatedDurationMinutes;
  final TerrainType terrain;
  final bool isPublic;
  final String? createdByUserId;
  final DateTime createdAt;
  final int? popularityScore; // For public routes

  RouteEntity({
    required this.id,
    required this.name,
    this.description,
    required this.waypoints,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.terrain,
    required this.isPublic,
    this.createdByUserId,
    required this.createdAt,
    this.popularityScore,
  });
}


