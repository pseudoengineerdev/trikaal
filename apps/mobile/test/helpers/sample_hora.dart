import 'sample_panchang.dart';

/// Builds a `/v1/panchang/compute` response whose `advanced.hora_timeline`
/// carries the full 24 planetary hours, computed from the same Vadodara
/// sunrise/sunset the panchang fixture uses (05:56 / 19:17, +05:30). This lets
/// the Hora page/controller tests exercise the real day/night split and the
/// Chaldean lord succession, with a deterministic "current hora" under a fixed
/// clock.
Map<String, dynamic> sampleHoraResponseJson(String dateIso) {
  final response = samplePanchangResponseJson(dateIso);
  final panchang = response['panchang'] as Map<String, dynamic>;
  final advanced = panchang['advanced'] as Map<String, dynamic>;
  advanced['hora_timeline'] = _buildHoraTimeline(dateIso);
  return response;
}

const List<String> _vedicGraha = <String>[
  'Surya', 'Chandra', 'Mangal', 'Budha', 'Guru', 'Shukra', 'Shani', //
];
const List<String> _englishGraha = <String>[
  'Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', //
];
// Chaldean hora succession (Sun, Venus, Mercury, Moon, Saturn, Jupiter, Mars).
const List<int> _horaSequence = <int>[0, 5, 3, 1, 6, 4, 2];

String _pad(int value) => value.toString().padLeft(2, '0');

Map<String, dynamic> _bundle(DateTime dt) {
  final iso = '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)}'
      'T${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}+05:30';
  return <String, dynamic>{
    'utc_iso': iso,
    'local_iso': iso,
    'local_time': '${_pad(dt.hour)}:${_pad(dt.minute)}',
  };
}

List<Map<String, dynamic>> _buildHoraTimeline(String dateIso) {
  final date = DateTime.parse(dateIso);
  final sunrise = DateTime(date.year, date.month, date.day, 5, 56);
  final sunset = DateTime(date.year, date.month, date.day, 19, 17);
  final nextSunrise = sunrise.add(const Duration(days: 1));

  final dayHora = Duration(seconds: sunset.difference(sunrise).inSeconds ~/ 12);
  final nightHora =
      Duration(seconds: nextSunrise.difference(sunset).inSeconds ~/ 12);

  // weekday_sunday0: Dart Sunday(7) -> 0 ... Saturday(6) -> 6.
  final weekdayLordIndex = date.weekday % 7;
  final sequenceStart = _horaSequence.indexOf(weekdayLordIndex);

  final slots = <Map<String, dynamic>>[];
  for (var slot = 0; slot < 24; slot++) {
    final lordIndex = _horaSequence[(sequenceStart + slot) % 7];
    final DateTime start;
    final DateTime end;
    final bool isDay;
    if (slot < 12) {
      start = sunrise.add(dayHora * slot);
      end = start.add(dayHora);
      isDay = true;
    } else {
      start = sunset.add(nightHora * (slot - 12));
      end = start.add(nightHora);
      isDay = false;
    }
    slots.add(<String, dynamic>{
      'lord_vedic': _vedicGraha[lordIndex],
      'lord_english': _englishGraha[lordIndex],
      'is_day': isDay,
      'start': _bundle(start),
      'end': _bundle(end),
    });
  }
  return slots;
}
