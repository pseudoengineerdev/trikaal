import '../../../../app/models/custom_place_payload.dart';
import 'compute_chart_models.dart';

class ComputeKaalSarpaRequest {
  const ComputeKaalSarpaRequest({
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

class ComputeKaalSarpaResponse {
  const ComputeKaalSarpaResponse({
    required this.profile,
    required this.normalizedInput,
    required this.resolvedPlace,
    required this.snapshot,
    required this.kaalSarpa,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> normalizedInput;
  final ResolvedPlace resolvedPlace;
  final Map<String, dynamic> snapshot;
  final KaalSarpaResult kaalSarpa;

  factory ComputeKaalSarpaResponse.fromJson(Map<String, dynamic> json) {
    return ComputeKaalSarpaResponse(
      profile: _asMap(json['profile']),
      normalizedInput: _asMap(json['normalized_input']),
      resolvedPlace: ResolvedPlace.fromJson(_asMap(json['resolved_place'])),
      snapshot: _asMap(json['snapshot']),
      kaalSarpa: KaalSarpaResult.fromJson(_asMap(json['kaal_sarpa'])),
    );
  }
}

class KaalSarpaResult {
  const KaalSarpaResult({
    this.ruleProfileId = '',
    this.method = '',
    this.isKaalSarpa = false,
    this.kaalSarpaType = '',
    this.rahuHouse = 0,
    this.ketuHouse = 0,
    this.enclosedSide = '',
    this.outsidePlanets = const <String>[],
    this.outsidePlanetCount = 0,
    this.axis = const KaalSarpaAxisEvidence(),
    this.classicalPlanets = const <String>[],
    this.planetEvidence = const <String, KaalSarpaPlanetEvidence>{},
    this.verdict = '',
  });

  final String ruleProfileId;
  final String method;
  final bool isKaalSarpa;
  final String kaalSarpaType;
  final int rahuHouse;
  final int ketuHouse;
  final String enclosedSide;
  final List<String> outsidePlanets;
  final int outsidePlanetCount;
  final KaalSarpaAxisEvidence axis;
  final List<String> classicalPlanets;
  final Map<String, KaalSarpaPlanetEvidence> planetEvidence;
  final String verdict;

  factory KaalSarpaResult.fromJson(Map<String, dynamic> json) {
    final evidence = _asMap(json['planet_evidence']).map(
      (String key, dynamic value) => MapEntry(
        key,
        KaalSarpaPlanetEvidence.fromJson(_asMap(value)),
      ),
    );
    return KaalSarpaResult(
      ruleProfileId: (json['rule_profile_id'] as String?) ?? '',
      method: (json['method'] as String?) ?? '',
      isKaalSarpa: (json['is_kaal_sarpa'] as bool?) ?? false,
      kaalSarpaType: (json['kaal_sarpa_type'] as String?) ?? '',
      rahuHouse: (json['rahu_house'] as num?)?.toInt() ?? 0,
      ketuHouse: (json['ketu_house'] as num?)?.toInt() ?? 0,
      enclosedSide: (json['enclosed_side'] as String?) ?? '',
      outsidePlanets: _readStringList(json['outside_planets']),
      outsidePlanetCount: (json['outside_planet_count'] as num?)?.toInt() ?? 0,
      axis: KaalSarpaAxisEvidence.fromJson(_asMap(json['axis'])),
      classicalPlanets: _readStringList(json['classical_planets']),
      planetEvidence: evidence,
      verdict: (json['verdict'] as String?) ?? '',
    );
  }
}

class KaalSarpaAxisEvidence {
  const KaalSarpaAxisEvidence({
    this.rahuDegree = 0,
    this.ketuDegree = 0,
    this.rahuToKetuEnclosure = false,
    this.ketuToRahuEnclosure = false,
  });

  final double rahuDegree;
  final double ketuDegree;
  final bool rahuToKetuEnclosure;
  final bool ketuToRahuEnclosure;

  factory KaalSarpaAxisEvidence.fromJson(Map<String, dynamic> json) {
    return KaalSarpaAxisEvidence(
      rahuDegree: (json['rahu_degree'] as num?)?.toDouble() ?? 0,
      ketuDegree: (json['ketu_degree'] as num?)?.toDouble() ?? 0,
      rahuToKetuEnclosure: (json['rahu_to_ketu_enclosure'] as bool?) ?? false,
      ketuToRahuEnclosure: (json['ketu_to_rahu_enclosure'] as bool?) ?? false,
    );
  }
}

class KaalSarpaPlanetEvidence {
  const KaalSarpaPlanetEvidence({
    this.siderealDegree = 0,
    this.withinRahuToKetuArc = false,
    this.withinKetuToRahuArc = false,
  });

  final double siderealDegree;
  final bool withinRahuToKetuArc;
  final bool withinKetuToRahuArc;

  factory KaalSarpaPlanetEvidence.fromJson(Map<String, dynamic> json) {
    return KaalSarpaPlanetEvidence(
      siderealDegree: (json['sidereal_degree'] as num?)?.toDouble() ?? 0,
      withinRahuToKetuArc: (json['within_rahu_to_ketu_arc'] as bool?) ?? false,
      withinKetuToRahuArc: (json['within_ketu_to_rahu_arc'] as bool?) ?? false,
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

List<String> _readStringList(Object? raw) {
  final list = raw as List<dynamic>?;
  if (list == null) {
    return const <String>[];
  }
  return list.map((dynamic value) => value.toString()).toList(growable: false);
}
