const List<String> _monthAbbreviations = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Compact social-style counts: 968, 1.2K, 4.5M.
String formatFeedCount(int count) {
  if (count >= 1000000) {
    return '${_trimTrailingZero((count / 1000000).toStringAsFixed(1))}M';
  }
  if (count >= 1000) {
    return '${_trimTrailingZero((count / 1000).toStringAsFixed(1))}K';
  }
  return '$count';
}

String _trimTrailingZero(String value) {
  return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
}

/// Compact social-style timestamps: 'now', '12m', '5h', '3d', then 'Mar 8'.
String formatFeedTimestamp(DateTime postedAt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(postedAt);
  if (difference.inMinutes < 1) {
    return 'now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}h';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}d';
  }
  final month = _monthAbbreviations[postedAt.month - 1];
  if (postedAt.year == reference.year) {
    return '$month ${postedAt.day}';
  }
  return '$month ${postedAt.day}, ${postedAt.year}';
}
