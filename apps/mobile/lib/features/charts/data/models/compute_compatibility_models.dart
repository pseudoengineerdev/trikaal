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
  });

  final String key;
  final String label;
  final double score;
  final double maxScore;
  final double percent;

  factory CompatibilityKutaComponent.fromJson(Map<String, dynamic> json) {
    return CompatibilityKutaComponent(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0.0,
      percent: (json['percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class CompatibilityManglik {
  const CompatibilityManglik({
    required this.maxScore,
    required this.score,
    required this.pairAlignment,
    required this.verdict,
    required this.boy,
    required this.girl,
  });

  final double maxScore;
  final double score;
  final String pairAlignment;
  final String verdict;
  final CompatibilityManglikPerson boy;
  final CompatibilityManglikPerson girl;

  factory CompatibilityManglik.fromJson(Map<String, dynamic> json) {
    return CompatibilityManglik(
      maxScore: (json['max_score'] as num?)?.toDouble() ?? 0.0,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      pairAlignment: (json['pair_alignment'] as String?) ?? '',
      verdict: (json['verdict'] as String?) ?? '',
      boy: CompatibilityManglikPerson.fromJson(_asMap(json['boy'])),
      girl: CompatibilityManglikPerson.fromJson(_asMap(json['girl'])),
    );
  }
}

class CompatibilityManglikPerson {
  const CompatibilityManglikPerson({
    required this.isManglik,
    required this.triggerCount,
  });

  final bool isManglik;
  final int triggerCount;

  factory CompatibilityManglikPerson.fromJson(Map<String, dynamic> json) {
    return CompatibilityManglikPerson(
      isManglik: (json['is_manglik'] as bool?) ?? false,
      triggerCount: (json['trigger_count'] as num?)?.toInt() ?? 0,
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
