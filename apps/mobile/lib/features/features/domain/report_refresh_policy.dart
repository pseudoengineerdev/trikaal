bool shouldAutoRefreshReportForDay(
  String asOfIso, {
  required DateTime now,
}) {
  final asOf = DateTime.tryParse(asOfIso);
  if (asOf == null) {
    return false;
  }
  final localAsOf = asOf.toLocal();
  return localAsOf.year != now.year ||
      localAsOf.month != now.month ||
      localAsOf.day != now.day;
}

String formatReportAsOfForDisplay(String asOfIso) {
  final asOf = DateTime.tryParse(asOfIso);
  if (asOf == null) {
    return '—';
  }
  final local = asOf.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String formatActiveWindowForDisplay(
  String activeFromIso,
  String activeUntilIso,
) {
  final start = _formatHumanDateTime(activeFromIso);
  final end = _formatHumanDateTime(activeUntilIso);
  if (start == '—' || end == '—') {
    return '$activeFromIso → $activeUntilIso';
  }
  return '$start → $end';
}

String _formatHumanDateTime(String isoValue) {
  final parsed = DateTime.tryParse(isoValue);
  if (parsed == null) {
    return '—';
  }
  final local = parsed.toLocal();
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[local.month - 1];
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour >= 12 ? 'PM' : 'AM';
  var hour = local.hour % 12;
  if (hour == 0) {
    hour = 12;
  }
  return '$month ${local.day}, ${local.year} $hour:$minute $meridiem';
}
