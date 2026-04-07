class ConnectionPreferences {
  ConnectionPreferences._();

  // Default ideal frequency in days for different connection levels
  static const double closeFriendDays = 7.0;
  static const double regularFriendDays = 14.0;
  static const double casualFriendDays = 30.0;

  /// Compute heart health (0–100) based on days since last interaction
  /// and ideal frequency. Linear decay: 100 at 0 days, 0 at 2× ideal frequency.
  static double computeHeartHealth(
    DateTime? lastInteraction,
    double idealFrequencyDays,
  ) {
    if (lastInteraction == null) return 0.0;
    final daysSince =
        DateTime.now().difference(lastInteraction).inHours / 24.0;
    if (daysSince <= 0) return 100.0;
    final health = 100.0 * (1.0 - daysSince / (idealFrequencyDays * 2.0));
    return health.clamp(0.0, 100.0);
  }

  /// Get the color name for a given health value.
  static String healthColor(double health) {
    if (health >= 70) return 'green';
    if (health >= 40) return 'yellow';
    return 'red';
  }
}
