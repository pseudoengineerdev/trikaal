import '../data/models/panchang_models.dart';
import '../presentation/state/panchang_time_format_state.dart';

const List<String> _monthAbbreviations = <String>[
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

/// A panchang moment split into the clock reading and an optional small
/// date suffix (e.g. `Jun 13`) so the UI can demote the date to a sub-line
/// instead of wrapping the whole value.
class PanchangMomentParts {
  const PanchangMomentParts({required this.time, this.dateSuffix});

  final String time;
  final String? dateSuffix;
}

/// A formatted window: the `start – end` clock span plus an optional date
/// suffix covering whichever ends fall outside the panchang date.
class PanchangRangeParts {
  const PanchangRangeParts({required this.span, this.dateSuffix});

  final String span;
  final String? dateSuffix;
}

/// Splits a panchang moment relative to the panchang date.
///
/// 12-hour mode: `07:36 AM` with a `Jun 13` suffix when the moment falls on
/// a different civil date. 24+ mode keeps the moment anchored to the
/// panchang date so post-midnight events roll past 24 (e.g. `25:13`) and
/// need no suffix.
PanchangMomentParts formatPanchangMomentParts(
  PanchangTimeBundle bundle, {
  required String panchangDateIso,
  required PanchangTimeFormat format,
}) {
  final localIso = bundle.localIso;
  if (localIso.length < 16) {
    return PanchangMomentParts(time: bundle.localTime);
  }
  final eventDate = DateTime.tryParse(localIso.substring(0, 10));
  final baseDate = DateTime.tryParse(panchangDateIso);
  final hour = int.tryParse(localIso.substring(11, 13));
  final minute = int.tryParse(localIso.substring(14, 16));
  if (eventDate == null || baseDate == null || hour == null || minute == null) {
    return PanchangMomentParts(time: bundle.localTime);
  }
  final dayDiff = eventDate.difference(baseDate).inDays;

  if (format == PanchangTimeFormat.h24plus) {
    final rolledHour = hour + (24 * dayDiff);
    if (rolledHour >= 0) {
      final hourLabel = rolledHour.toString().padLeft(2, '0');
      final minuteLabel = minute.toString().padLeft(2, '0');
      return PanchangMomentParts(time: '$hourLabel:$minuteLabel');
    }
    // Before the panchang date (e.g. a tithi that began yesterday): fall
    // through to the dated 12-hour form instead of a negative clock.
  }

  final hour12 = hour % 12 == 0 ? 12 : hour % 12;
  final suffix = hour < 12 ? 'AM' : 'PM';
  final minuteLabel = minute.toString().padLeft(2, '0');
  final timeLabel = '${hour12.toString().padLeft(2, '0')}:$minuteLabel $suffix';
  if (dayDiff == 0) {
    return PanchangMomentParts(time: timeLabel);
  }
  final monthLabel = _monthAbbreviations[eventDate.month - 1];
  return PanchangMomentParts(
    time: timeLabel,
    dateSuffix: '$monthLabel ${eventDate.day}',
  );
}

/// Splits a window into the clock span and one combined date suffix.
PanchangRangeParts formatPanchangRangeParts(
  PanchangWindow window, {
  required String panchangDateIso,
  required PanchangTimeFormat format,
}) {
  final start = formatPanchangMomentParts(
    window.start,
    panchangDateIso: panchangDateIso,
    format: format,
  );
  final end = formatPanchangMomentParts(
    window.end,
    panchangDateIso: panchangDateIso,
    format: format,
  );
  final span = '${start.time} – ${end.time}';
  final startSuffix = start.dateSuffix;
  final endSuffix = end.dateSuffix;
  String? dateSuffix;
  if (startSuffix != null && endSuffix != null) {
    dateSuffix =
        startSuffix == endSuffix ? startSuffix : '$startSuffix – $endSuffix';
  } else if (endSuffix != null) {
    dateSuffix = 'ends $endSuffix';
  } else if (startSuffix != null) {
    dateSuffix = 'from $startSuffix';
  }
  return PanchangRangeParts(span: span, dateSuffix: dateSuffix);
}

/// One-line form of [formatPanchangMomentParts] for places where a sub-line
/// is not available.
String formatPanchangMoment(
  PanchangTimeBundle bundle, {
  required String panchangDateIso,
  required PanchangTimeFormat format,
}) {
  final parts = formatPanchangMomentParts(
    bundle,
    panchangDateIso: panchangDateIso,
    format: format,
  );
  if (parts.dateSuffix == null) {
    return parts.time;
  }
  return '${parts.time}, ${parts.dateSuffix}';
}

/// One-line form of [formatPanchangRangeParts].
String formatPanchangRange(
  PanchangWindow window, {
  required String panchangDateIso,
  required PanchangTimeFormat format,
}) {
  final start = formatPanchangMoment(
    window.start,
    panchangDateIso: panchangDateIso,
    format: format,
  );
  final end = formatPanchangMoment(
    window.end,
    panchangDateIso: panchangDateIso,
    format: format,
  );
  return '$start – $end';
}
