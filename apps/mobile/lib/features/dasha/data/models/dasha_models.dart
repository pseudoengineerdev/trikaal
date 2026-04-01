import '../../../../app/models/custom_place_payload.dart';

class DashaSummary {
  const DashaSummary({
    required this.system,
    required this.currentMahaDasha,
    required this.currentAntarDasha,
    required this.activeFrom,
    required this.activeUntil,
  });

  final String system;
  final String currentMahaDasha;
  final String currentAntarDasha;
  final String activeFrom;
  final String activeUntil;

  factory DashaSummary.fromJson(Map<String, dynamic> json) {
    return DashaSummary(
      system: (json['system'] as String?) ?? '',
      currentMahaDasha: (json['current_maha_dasha'] as String?) ?? '',
      currentAntarDasha: (json['current_antar_dasha'] as String?) ?? '',
      activeFrom: (json['active_from'] as String?) ?? '',
      activeUntil: (json['active_until'] as String?) ?? '',
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
