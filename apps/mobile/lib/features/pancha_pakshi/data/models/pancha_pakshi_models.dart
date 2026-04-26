import '../../../../app/models/custom_place_payload.dart';

class PanchaPakshiRequest {
  const PanchaPakshiRequest({
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    this.customPlace,
    this.runtimePlaceOfObservation,
    this.runtimeCustomPlace,
  });

  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;
  final String? runtimePlaceOfObservation;
  final CustomPlacePayload? runtimeCustomPlace;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
      if (customPlace != null) 'custom_place': customPlace!.toJson(),
      if (runtimePlaceOfObservation != null)
        'runtime_place_of_observation': runtimePlaceOfObservation,
      if (runtimeCustomPlace != null)
        'runtime_custom_place': runtimeCustomPlace!.toJson(),
    };
  }
}

class PanchaPakshiResponse {
  const PanchaPakshiResponse({
    required this.profile,
    required this.normalizedInput,
    required this.resolvedPlace,
    required this.panchaPakshi,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> normalizedInput;
  final Map<String, dynamic> resolvedPlace;
  final PanchaPakshiPayload panchaPakshi;

  factory PanchaPakshiResponse.fromJson(Map<String, dynamic> json) {
    return PanchaPakshiResponse(
      profile: _readMap(json, 'profile'),
      normalizedInput: _readMap(json, 'normalized_input'),
      resolvedPlace: _readMap(json, 'resolved_place'),
      panchaPakshi: PanchaPakshiPayload.fromJson(
        _readMap(json, 'pancha_pakshi'),
      ),
    );
  }
}

class PanchaPakshiPayload {
  const PanchaPakshiPayload({
    required this.version,
    required this.birth,
    required this.runtime,
    required this.active,
    required this.timeline,
  });

  final String version;
  final PanchaPakshiBirth birth;
  final PanchaPakshiRuntime runtime;
  final PanchaPakshiActive active;
  final List<PanchaPakshiMajorWindow> timeline;

  factory PanchaPakshiPayload.fromJson(Map<String, dynamic> json) {
    final timelineRaw = json['timeline'];
    if (timelineRaw is! List) {
      throw const FormatException(
          'Field "pancha_pakshi.timeline" must be a list');
    }
    return PanchaPakshiPayload(
      version: _readString(json, 'version'),
      birth: PanchaPakshiBirth.fromJson(_readMap(json, 'birth')),
      runtime: PanchaPakshiRuntime.fromJson(_readMap(json, 'runtime')),
      active: PanchaPakshiActive.fromJson(_readMap(json, 'active')),
      timeline: timelineRaw
          .map(
            (Object? raw) => PanchaPakshiMajorWindow.fromJson(
              _asMap(raw, 'pancha_pakshi.timeline[]'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class PanchaPakshiBirth {
  const PanchaPakshiBirth({
    required this.nakshatraNumber,
    required this.nakshatraName,
    required this.paksha,
    required this.pakshi,
  });

  final int nakshatraNumber;
  final String nakshatraName;
  final String paksha;
  final String pakshi;

  factory PanchaPakshiBirth.fromJson(Map<String, dynamic> json) {
    return PanchaPakshiBirth(
      nakshatraNumber: _readInt(json, 'nakshatra_number'),
      nakshatraName: _readString(json, 'nakshatra_name'),
      paksha: _readString(json, 'paksha'),
      pakshi: _readString(json, 'pakshi'),
    );
  }
}

class PanchaPakshiRuntime {
  const PanchaPakshiRuntime({
    required this.asOfLocalIso,
    required this.referencePlaceLabel,
    required this.referenceTimezone,
    required this.weekday,
    required this.paksha,
    required this.phase,
    required this.phaseWindowStartLocalIso,
    required this.phaseWindowEndLocalIso,
    required this.nextTransitionLocalIso,
    required this.secondsRemainingInActiveSubActivity,
  });

  final String asOfLocalIso;
  final String referencePlaceLabel;
  final String referenceTimezone;
  final String weekday;
  final String paksha;
  final String phase;
  final String phaseWindowStartLocalIso;
  final String phaseWindowEndLocalIso;
  final String nextTransitionLocalIso;
  final int secondsRemainingInActiveSubActivity;

  factory PanchaPakshiRuntime.fromJson(Map<String, dynamic> json) {
    return PanchaPakshiRuntime(
      asOfLocalIso: _readString(json, 'as_of_local_iso'),
      referencePlaceLabel: _readString(json, 'reference_place_label'),
      referenceTimezone: _readString(json, 'reference_timezone'),
      weekday: _readString(json, 'weekday'),
      paksha: _readString(json, 'paksha'),
      phase: _readString(json, 'phase'),
      phaseWindowStartLocalIso:
          _readString(json, 'phase_window_start_local_iso'),
      phaseWindowEndLocalIso: _readString(json, 'phase_window_end_local_iso'),
      nextTransitionLocalIso: _readString(json, 'next_transition_local_iso'),
      secondsRemainingInActiveSubActivity: _readInt(
        json,
        'seconds_remaining_in_active_sub_activity',
      ),
    );
  }
}

class PanchaPakshiActive {
  const PanchaPakshiActive({
    required this.majorIndex,
    required this.mainBird,
    required this.mainActivity,
    required this.subActivity,
  });

  final int majorIndex;
  final String mainBird;
  final String mainActivity;
  final PanchaPakshiSubWindow subActivity;

  factory PanchaPakshiActive.fromJson(Map<String, dynamic> json) {
    return PanchaPakshiActive(
      majorIndex: _readInt(json, 'major_index'),
      mainBird: _readString(json, 'main_bird'),
      mainActivity: _readString(json, 'main_activity'),
      subActivity:
          PanchaPakshiSubWindow.fromJson(_readMap(json, 'sub_activity')),
    );
  }
}

class PanchaPakshiMajorWindow {
  const PanchaPakshiMajorWindow({
    required this.majorIndex,
    required this.phase,
    required this.paksha,
    required this.startLocalIso,
    required this.endLocalIso,
    required this.mainBird,
    required this.mainActivity,
    required this.durationMinutes,
    required this.subTimeline,
  });

  final int majorIndex;
  final String phase;
  final String paksha;
  final String startLocalIso;
  final String endLocalIso;
  final String mainBird;
  final String mainActivity;
  final double durationMinutes;
  final List<PanchaPakshiSubWindow> subTimeline;

  factory PanchaPakshiMajorWindow.fromJson(Map<String, dynamic> json) {
    final subRaw = json['sub_timeline'];
    if (subRaw is! List) {
      throw const FormatException('Field "sub_timeline" must be a list');
    }
    return PanchaPakshiMajorWindow(
      majorIndex: _readInt(json, 'major_index'),
      phase: _readStringOrFallback(json, 'phase', ''),
      paksha: _readStringOrFallback(json, 'paksha', ''),
      startLocalIso: _readString(json, 'start_local_iso'),
      endLocalIso: _readString(json, 'end_local_iso'),
      mainBird: _readString(json, 'main_bird'),
      mainActivity: _readString(json, 'main_activity'),
      durationMinutes: _readDouble(json, 'duration_minutes'),
      subTimeline: subRaw
          .map(
            (Object? raw) => PanchaPakshiSubWindow.fromJson(
              _asMap(raw, 'sub_timeline[]'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class PanchaPakshiSubWindow {
  const PanchaPakshiSubWindow({
    required this.startLocalIso,
    required this.endLocalIso,
    required this.bird,
    required this.activity,
    required this.relation,
    required this.effect,
    required this.powerFactor,
    required this.rating,
    required this.durationMinutes,
  });

  final String startLocalIso;
  final String endLocalIso;
  final String bird;
  final String activity;
  final String relation;
  final String effect;
  final double powerFactor;
  final int rating;
  final double durationMinutes;

  factory PanchaPakshiSubWindow.fromJson(Map<String, dynamic> json) {
    return PanchaPakshiSubWindow(
      startLocalIso: _readString(json, 'start_local_iso'),
      endLocalIso: _readString(json, 'end_local_iso'),
      bird: _readString(json, 'bird'),
      activity: _readString(json, 'activity'),
      relation: _readString(json, 'relation'),
      effect: _readString(json, 'effect'),
      powerFactor: _readDouble(json, 'power_factor'),
      rating: _readInt(json, 'rating'),
      durationMinutes: _readDouble(json, 'duration_minutes'),
    );
  }
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, String key) {
  return _asMap(json[key], key);
}

Map<String, dynamic> _asMap(Object? value, String key) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (Object? mapKey, Object? mapValue) =>
          MapEntry(mapKey.toString(), mapValue),
    );
  }
  throw FormatException('Field "$key" must be an object');
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw FormatException('Field "$key" must be a string');
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  throw FormatException('Field "$key" must be an integer');
}

String _readStringOrFallback(
  Map<String, dynamic> json,
  String key,
  String fallback,
) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  return fallback;
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  throw FormatException('Field "$key" must be numeric');
}
