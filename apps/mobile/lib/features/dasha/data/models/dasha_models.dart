import '../../../../app/models/custom_place_payload.dart';

class DashaSummary {
  const DashaSummary({
    required this.system,
    required this.asOfIso,
    required this.birthMoonNakshatra,
    required this.currentMahaDasha,
    required this.currentAntarDasha,
    required this.activeFrom,
    required this.activeUntil,
    required this.currentMahaStart,
    required this.currentMahaEnd,
    required this.mahaTimeline,
    required this.antarTimelineCurrentMaha,
  });

  final String system;
  final String asOfIso;
  final String birthMoonNakshatra;
  final String currentMahaDasha;
  final String currentAntarDasha;
  final String activeFrom;
  final String activeUntil;
  final String currentMahaStart;
  final String currentMahaEnd;
  final List<DashaPeriod> mahaTimeline;
  final List<DashaPeriod> antarTimelineCurrentMaha;

  factory DashaSummary.fromJson(Map<String, dynamic> json) {
    return DashaSummary(
      system: (json['system'] as String?) ?? '',
      asOfIso: (json['as_of_iso'] as String?) ?? '',
      birthMoonNakshatra: (json['birth_moon_nakshatra'] as String?) ?? '',
      currentMahaDasha: (json['current_maha_dasha'] as String?) ?? '',
      currentAntarDasha: (json['current_antar_dasha'] as String?) ?? '',
      activeFrom: (json['active_from'] as String?) ?? '',
      activeUntil: (json['active_until'] as String?) ?? '',
      currentMahaStart: (json['current_maha_start'] as String?) ?? '',
      currentMahaEnd: (json['current_maha_end'] as String?) ?? '',
      mahaTimeline: _asList(json['maha_timeline'])
          .map((Object? item) => DashaPeriod.fromJson(_asMap(item)))
          .toList(growable: false),
      antarTimelineCurrentMaha: _asList(json['antar_timeline_current_maha'])
          .map((Object? item) => DashaPeriod.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }
}

class DashaPeriod {
  const DashaPeriod({
    required this.lord,
    required this.lordKey,
    required this.start,
    required this.end,
    required this.active,
  });

  final String lord;
  final String lordKey;
  final String start;
  final String end;
  final bool active;

  factory DashaPeriod.fromJson(Map<String, dynamic> json) {
    return DashaPeriod(
      lord: (json['lord'] as String?) ?? '',
      lordKey: (json['lord_key'] as String?) ?? '',
      start: (json['start'] as String?) ?? '',
      end: (json['end'] as String?) ?? '',
      active: (json['active'] as bool?) ?? false,
    );
  }
}

class DashaComputeRequest {
  const DashaComputeRequest({
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    this.customPlace,
  });

  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
      if (customPlace != null) 'custom_place': customPlace!.toJson(),
    };
  }
}

class DashaComputeResponse {
  const DashaComputeResponse({
    required this.profile,
    required this.normalizedInput,
    required this.resolvedPlace,
    required this.dasha,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> normalizedInput;
  final Map<String, dynamic> resolvedPlace;
  final DashaSummary dasha;

  factory DashaComputeResponse.fromJson(Map<String, dynamic> json) {
    return DashaComputeResponse(
      profile: _asMap(json['profile']),
      normalizedInput: _asMap(json['normalized_input']),
      resolvedPlace: _asMap(json['resolved_place']),
      dasha: DashaSummary.fromJson(_asMap(json['dasha'])),
    );
  }
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Object?> _asList(Object? raw) {
  if (raw is List<Object?>) {
    return raw;
  }
  if (raw is List) {
    return raw.cast<Object?>();
  }
  return const <Object?>[];
}
