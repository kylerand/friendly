enum FriendshipStatus { pending, confirmed, archived, blocked }

class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final FriendshipStatus status;
  final double connectionDrift;
  final bool nudgeEligible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.connectionDrift = 0,
    this.nudgeEligible = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) => Friendship(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        friendId: json['friend_id'] as String,
        status: _parseStatus(json['status'] as String? ?? 'pending'),
        connectionDrift:
            (json['connection_drift'] as num?)?.toDouble() ?? 0,
        nudgeEligible: json['nudge_eligible'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  static FriendshipStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':
        return FriendshipStatus.confirmed;
      case 'archived':
        return FriendshipStatus.archived;
      case 'blocked':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }
}
