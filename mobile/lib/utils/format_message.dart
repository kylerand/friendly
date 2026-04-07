class FormatMessage {
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '${years}y ago';
    }
    if (diff.inDays > 30) {
      final months = (diff.inDays / 30).floor();
      return '${months}mo ago';
    }
    if (diff.inDays > 7) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}w ago';
    }
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    return 'just now';
  }

  static String greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
