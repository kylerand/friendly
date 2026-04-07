import 'friendship.dart';

class Friend {
  final String friendshipId;
  final String friendId;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final Map<String, dynamic>? metadata;
  final FriendshipStatus status;
  final DateTime? lastInteraction;
  final double heartHealth;

  const Friend({
    required this.friendshipId,
    required this.friendId,
    required this.displayName,
    this.email,
    this.phoneNumber,
    this.metadata,
    required this.status,
    this.lastInteraction,
    this.heartHealth = 100.0,
  });
}
