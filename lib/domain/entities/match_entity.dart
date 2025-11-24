import 'package:byure/domain/entities/user_entity.dart';

/// Match entity representing a match between two users
class MatchEntity {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime matchedAt;
  final MatchStatus status;
  final double? compatibilityScore;
  final UserEntity? otherUser; // Populated when fetching matches

  MatchEntity({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.matchedAt,
    required this.status,
    this.compatibilityScore,
    this.otherUser,
  });
}

enum MatchStatus {
  pending,
  accepted,
  declined,
  blocked,
}


