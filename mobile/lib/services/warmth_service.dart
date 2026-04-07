import '../constants/nudge_copy.dart';
import '../models/friend.dart';

class WarmthService {
  static WarmthTier computeTier(int weekStreak) {
    if (weekStreak >= 4) return WarmthTier.radiant;
    if (weekStreak >= 2) return WarmthTier.warm;
    if (weekStreak >= 1) return WarmthTier.gentle;
    return WarmthTier.quiet;
  }

  static int computeWeekStreak(List<DateTime> interactionDates) {
    if (interactionDates.isEmpty) return 0;
    final sorted = List<DateTime>.from(interactionDates)
      ..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    int streak = 0;
    for (int w = 0; w < 52; w++) {
      final weekStart = now.subtract(Duration(days: 7 * (w + 1)));
      final weekEnd = now.subtract(Duration(days: 7 * w));
      final hasInteraction =
          sorted.any((d) => d.isAfter(weekStart) && d.isBefore(weekEnd));
      if (hasInteraction) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static Friend? suggestFriend(List<Friend> friends) {
    final accepted =
        friends.where((f) => f.status.name == 'confirmed').toList();
    if (accepted.isEmpty) return null;
    accepted.sort((a, b) => a.heartHealth.compareTo(b.heartHealth));
    return accepted.first;
  }
}
