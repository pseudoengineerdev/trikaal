import '../../../../app/models/custom_place_payload.dart';
import 'compute_chart_models.dart';

class CompatibilityPersonRequestPayload {
  const CompatibilityPersonRequestPayload({
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

class ComputeCompatibilityRequest {
  const ComputeCompatibilityRequest({
    required this.primary,
    required this.partner,
    required this.primaryRole,
  });

  final CompatibilityPersonRequestPayload primary;
  final CompatibilityPersonRequestPayload partner;
  final String primaryRole;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'primary': primary.toJson(),
      'partner': partner.toJson(),
      'primary_role': primaryRole,
    };
  }
}

class ComputeCompatibilityResponse {
  const ComputeCompatibilityResponse({
    required this.profile,
    required this.roles,
    required this.primary,
    required this.partner,
    required this.compatibility,
  });

  final CompatibilityProfile profile;
  final CompatibilityRoleMap roles;
  final CompatibilityPersonResolved primary;
  final CompatibilityPersonResolved partner;
  final CompatibilityResult compatibility;

  factory ComputeCompatibilityResponse.fromJson(Map<String, dynamic> json) {
    return ComputeCompatibilityResponse(
      profile: CompatibilityProfile.fromJson(_asMap(json['profile'])),
      roles: CompatibilityRoleMap.fromJson(_asMap(json['roles'])),
      primary: CompatibilityPersonResolved.fromJson(_asMap(json['primary'])),
      partner: CompatibilityPersonResolved.fromJson(_asMap(json['partner'])),
      compatibility:
          CompatibilityResult.fromJson(_asMap(json['compatibility'])),
    );
  }
}

class CompatibilityProfile {
  const CompatibilityProfile({
    required this.profileId,
    required this.zodiacSystem,
    required this.ayanamsha,
    required this.calculationMethod,
  });

  final String profileId;
  final String zodiacSystem;
  final String ayanamsha;
  final String calculationMethod;

  factory CompatibilityProfile.fromJson(Map<String, dynamic> json) {
    return CompatibilityProfile(
      profileId: (json['profile_id'] as String?) ?? '',
      zodiacSystem: (json['zodiac_system'] as String?) ?? '',
      ayanamsha: (json['ayanamsha'] as String?) ?? '',
      calculationMethod: (json['calculation_method'] as String?) ?? '',
    );
  }
}

class CompatibilityRoleMap {
  const CompatibilityRoleMap({
    required this.primary,
    required this.partner,
  });

  final String primary;
  final String partner;

  factory CompatibilityRoleMap.fromJson(Map<String, dynamic> json) {
    return CompatibilityRoleMap(
      primary: (json['primary'] as String?) ?? '',
      partner: (json['partner'] as String?) ?? '',
    );
  }
}

class CompatibilityPersonResolved {
  const CompatibilityPersonResolved({
    required this.normalizedInput,
    required this.resolvedPlace,
    required this.snapshot,
  });

  final Map<String, dynamic> normalizedInput;
  final ResolvedPlace resolvedPlace;
  final Map<String, dynamic> snapshot;

  factory CompatibilityPersonResolved.fromJson(Map<String, dynamic> json) {
    return CompatibilityPersonResolved(
      normalizedInput: _asMap(json['normalized_input']),
      resolvedPlace: ResolvedPlace.fromJson(_asMap(json['resolved_place'])),
      snapshot: _asMap(json['snapshot']),
    );
  }
}

class CompatibilityResult {
  const CompatibilityResult({
    required this.ashtaKuta,
    required this.manglik,
    required this.d1d9,
    required this.summary,
  });

  final CompatibilityAshtaKuta ashtaKuta;
  final CompatibilityManglik manglik;
  final Map<String, dynamic> d1d9;
  final CompatibilitySummary summary;

  factory CompatibilityResult.fromJson(Map<String, dynamic> json) {
    return CompatibilityResult(
      ashtaKuta: CompatibilityAshtaKuta.fromJson(_asMap(json['ashta_kuta'])),
      manglik: CompatibilityManglik.fromJson(_asMap(json['manglik'])),
      d1d9: _asMap(json['d1_d9']),
      summary: CompatibilitySummary.fromJson(_asMap(json['summary'])),
    );
  }
}

class CompatibilityAshtaKuta {
  const CompatibilityAshtaKuta({
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.classification,
    required this.components,
    required this.nadiMatch,
    required this.bhakootMatch,
  });

  final double totalScore;
  final double maxScore;
  final double percentage;
  final String classification;
  final List<CompatibilityKutaComponent> components;
  final bool nadiMatch;
  final bool bhakootMatch;

  factory CompatibilityAshtaKuta.fromJson(Map<String, dynamic> json) {
    final rawComponents =
        (json['components'] as List<dynamic>?) ?? const <dynamic>[];
    return CompatibilityAshtaKuta(
      totalScore: (json['total_score'] as num?)?.toDouble() ?? 0.0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      classification: (json['classification'] as String?) ?? '',
      components: rawComponents
          .map((raw) => CompatibilityKutaComponent.fromJson(_asMap(raw)))
          .toList(growable: false),
      nadiMatch: (json['nadi_match'] as bool?) ?? false,
      bhakootMatch: (json['bhakoot_match'] as bool?) ?? false,
    );
  }
}

class CompatibilityKutaComponent {
  const CompatibilityKutaComponent({
    required this.key,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.percent,
    required this.boyValue,
    required this.girlValue,
    required this.areaOfLife,
    required this.description,
  });

  final String key;
  final String label;
  final double score;
  final double maxScore;
  final double percent;
  final String boyValue;
  final String girlValue;
  final String areaOfLife;
  final String description;

  factory CompatibilityKutaComponent.fromJson(Map<String, dynamic> json) {
    return CompatibilityKutaComponent(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0.0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
      boyValue: (json['boy_value'] as String?) ?? '',
      girlValue: (json['girl_value'] as String?) ?? '',
      areaOfLife: (json['area_of_life'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
    );
  }
}

class CompatibilityManglik {
  const CompatibilityManglik({
    this.ruleProfileId = '',
    this.method = '',
    required this.maxScore,
    required this.score,
    required this.pairAlignment,
    required this.verdict,
    this.evidence = const CompatibilityManglikEvidence(),
    required this.boy,
    required this.girl,
  });

  final String ruleProfileId;
  final String method;
  final double maxScore;
  final double score;
  final String pairAlignment;
  final String verdict;
  final CompatibilityManglikEvidence evidence;
  final CompatibilityManglikPerson boy;
  final CompatibilityManglikPerson girl;

  factory CompatibilityManglik.fromJson(Map<String, dynamic> json) {
    return CompatibilityManglik(
      ruleProfileId: (json['rule_profile_id'] as String?) ?? '',
      method: (json['method'] as String?) ?? '',
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      pairAlignment: (json['pair_alignment'] as String?) ?? '',
      verdict: (json['verdict'] as String?) ?? '',
      evidence: CompatibilityManglikEvidence.fromJson(_asMap(json['evidence'])),
      boy: CompatibilityManglikPerson.fromJson(_asMap(json['boy'])),
      girl: CompatibilityManglikPerson.fromJson(_asMap(json['girl'])),
    );
  }
}

class CompatibilityManglikEvidence {
  const CompatibilityManglikEvidence({
    this.pairRule = '',
    this.boyTriggerCount = 0,
    this.girlTriggerCount = 0,
    this.triggerCountGap = 0,
    this.sameManglikStatus = false,
  });

  final String pairRule;
  final int boyTriggerCount;
  final int girlTriggerCount;
  final int triggerCountGap;
  final bool sameManglikStatus;

  factory CompatibilityManglikEvidence.fromJson(Map<String, dynamic> json) {
    return CompatibilityManglikEvidence(
      pairRule: (json['pair_rule'] as String?) ?? '',
      boyTriggerCount: (json['boy_trigger_count'] as num?)?.toInt() ?? 0,
      girlTriggerCount: (json['girl_trigger_count'] as num?)?.toInt() ?? 0,
      triggerCountGap: (json['trigger_count_gap'] as num?)?.toInt() ?? 0,
      sameManglikStatus: (json['same_manglik_status'] as bool?) ?? false,
    );
  }
}

class CompatibilityManglikPerson {
  const CompatibilityManglikPerson({
    required this.isManglik,
    required this.triggerCount,
    this.rawTriggerCount = 0,
    this.doshaPercent = 0,
    this.rawDoshaPercent = 0,
    this.triggerHouses = const <int>[],
    this.activeReferences = const <String>[],
    this.inactiveReferences = const <String>[],
    this.cancelledReferences = const <String>[],
    this.cancellationApplied = false,
    this.cancellationReasons = const <String>[],
    this.referenceEvidence =
        const <String, CompatibilityManglikReferenceEvidence>{},
    this.marsHouseFromLagna = 0,
    this.marsHouseFromMoon = 0,
    this.marsHouseFromVenus = 0,
  });

  final bool isManglik;
  final int triggerCount;
  final int rawTriggerCount;
  final int doshaPercent;
  final int rawDoshaPercent;
  final List<int> triggerHouses;
  final List<String> activeReferences;
  final List<String> inactiveReferences;
  final List<String> cancelledReferences;
  final bool cancellationApplied;
  final List<String> cancellationReasons;
  final Map<String, CompatibilityManglikReferenceEvidence> referenceEvidence;
  final int marsHouseFromLagna;
  final int marsHouseFromMoon;
  final int marsHouseFromVenus;

  factory CompatibilityManglikPerson.fromJson(Map<String, dynamic> json) {
    final rawReferenceEvidence = _asMap(json['reference_evidence']);
    final referenceEvidence = rawReferenceEvidence.map(
      (String key, dynamic value) => MapEntry(
        key,
        CompatibilityManglikReferenceEvidence.fromJson(_asMap(value)),
      ),
    );
    return CompatibilityManglikPerson(
      isManglik: (json['is_manglik'] as bool?) ?? false,
      triggerCount: (json['trigger_count'] as num?)?.toInt() ?? 0,
      rawTriggerCount: (json['raw_trigger_count'] as num?)?.toInt() ?? 0,
      doshaPercent: (json['dosha_percent'] as num?)?.toInt() ?? 0,
      rawDoshaPercent: (json['raw_dosha_percent'] as num?)?.toInt() ?? 0,
      triggerHouses: _readIntList(json['trigger_houses']),
      activeReferences: _readStringList(json['active_references']),
      inactiveReferences: _readStringList(json['inactive_references']),
      cancelledReferences: _readStringList(json['cancelled_references']),
      cancellationApplied: (json['cancellation_applied'] as bool?) ?? false,
      cancellationReasons: _readStringList(json['cancellation_reasons']),
      referenceEvidence: referenceEvidence,
      marsHouseFromLagna: (json['mars_house_from_lagna'] as num?)?.toInt() ?? 0,
      marsHouseFromMoon: (json['mars_house_from_moon'] as num?)?.toInt() ?? 0,
      marsHouseFromVenus: (json['mars_house_from_venus'] as num?)?.toInt() ?? 0,
    );
  }
}

class CompatibilityManglikReferenceEvidence {
  const CompatibilityManglikReferenceEvidence({
    this.referenceKey = '',
    this.referenceLabel = '',
    this.marsHouse = 0,
    this.triggered = false,
    this.effectiveTriggered = false,
    this.cancelled = false,
    this.rawDoshaPercent = 0,
    this.doshaPercent = 0,
    this.helperPlanetCount = 0,
    this.helperPlanets = const <String>[],
    this.helperPlanetLabels = const <String>[],
    this.helperPlanetHouses = const <String, int>{},
    this.helpingReason = '',
    this.jupiterHouseFromReference = 0,
    this.jupiterAspectsMars = false,
    this.jupiterAspectHouse = 0,
    this.exceptionRuleId = '',
    this.exceptionReason = '',
    this.cancellationRuleIds = const <String>[],
    this.cancellationReasons = const <String>[],
    this.ruleHouses = const <int>[],
    this.reason = '',
  });

  final String referenceKey;
  final String referenceLabel;
  final int marsHouse;
  final bool triggered;
  final bool effectiveTriggered;
  final bool cancelled;
  final int rawDoshaPercent;
  final int doshaPercent;
  final int helperPlanetCount;
  final List<String> helperPlanets;
  final List<String> helperPlanetLabels;
  final Map<String, int> helperPlanetHouses;
  final String helpingReason;
  final int jupiterHouseFromReference;
  final bool jupiterAspectsMars;
  final int jupiterAspectHouse;
  final String exceptionRuleId;
  final String exceptionReason;
  final List<String> cancellationRuleIds;
  final List<String> cancellationReasons;
  final List<int> ruleHouses;
  final String reason;

  factory CompatibilityManglikReferenceEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawHelperHouses = _asMap(json['helper_planet_houses']);
    final helperPlanetHouses = rawHelperHouses.map(
      (String key, dynamic value) => MapEntry(
        key,
        (value as num?)?.toInt() ?? 0,
      ),
    );
    return CompatibilityManglikReferenceEvidence(
      referenceKey: (json['reference_key'] as String?) ?? '',
      referenceLabel: (json['reference_label'] as String?) ?? '',
      marsHouse: (json['mars_house'] as num?)?.toInt() ?? 0,
      triggered: (json['triggered'] as bool?) ?? false,
      effectiveTriggered: (json['effective_triggered'] as bool?) ?? false,
      cancelled: (json['cancelled'] as bool?) ?? false,
      rawDoshaPercent: (json['raw_dosha_percent'] as num?)?.toInt() ?? 0,
      doshaPercent: (json['dosha_percent'] as num?)?.toInt() ?? 0,
      helperPlanetCount: (json['helper_planet_count'] as num?)?.toInt() ?? 0,
      helperPlanets: _readStringList(json['helper_planets']),
      helperPlanetLabels: _readStringList(json['helper_planet_labels']),
      helperPlanetHouses: helperPlanetHouses,
      helpingReason: (json['helping_reason'] as String?) ?? '',
      jupiterHouseFromReference:
          (json['jupiter_house_from_reference'] as num?)?.toInt() ?? 0,
      jupiterAspectsMars: (json['jupiter_aspects_mars'] as bool?) ?? false,
      jupiterAspectHouse: (json['jupiter_aspect_house'] as num?)?.toInt() ?? 0,
      exceptionRuleId: (json['exception_rule_id'] as String?) ?? '',
      exceptionReason: (json['exception_reason'] as String?) ?? '',
      cancellationRuleIds: _readStringList(json['cancellation_rule_ids']),
      cancellationReasons: _readStringList(json['cancellation_reasons']),
      ruleHouses: _readIntList(json['rule_houses']),
      reason: (json['reason'] as String?) ?? '',
    );
  }
}

class CompatibilitySummary {
  const CompatibilitySummary({
    required this.overallBand,
    required this.gunaScore,
    required this.gunaScoreMax,
    required this.manglikAlignment,
    required this.nadiMatch,
    required this.bhakootMatch,
  });

  final String overallBand;
  final double gunaScore;
  final double gunaScoreMax;
  final String manglikAlignment;
  final bool nadiMatch;
  final bool bhakootMatch;

  factory CompatibilitySummary.fromJson(Map<String, dynamic> json) {
    return CompatibilitySummary(
      overallBand: (json['overall_band'] as String?) ?? '',
      gunaScore: (json['guna_score'] as num?)?.toDouble() ?? 0.0,
      gunaScoreMax: (json['guna_score_max'] as num?)?.toDouble() ?? 0.0,
      manglikAlignment: (json['manglik_alignment'] as String?) ?? '',
      nadiMatch: (json['nadi_match'] as bool?) ?? false,
      bhakootMatch: (json['bhakoot_match'] as bool?) ?? false,
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

List<int> _readIntList(Object? raw) {
  final list = raw as List<dynamic>?;
  if (list == null) {
    return const <int>[];
  }
  return list.map((dynamic value) => (value as num).toInt()).toList();
}

List<String> _readStringList(Object? raw) {
  final list = raw as List<dynamic>?;
  if (list == null) {
    return const <String>[];
  }
  return list.map((dynamic value) => value.toString()).toList();
}
