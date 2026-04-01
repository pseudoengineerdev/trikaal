import '../../../../app/models/custom_place_payload.dart';

class ComputeChartRequest {
  const ComputeChartRequest({
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

class ComputeChartResponse {
  const ComputeChartResponse({
    required this.profile,
    required this.normalizedInput,
    required this.resolvedPlace,
    required this.snapshot,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> normalizedInput;
  final ResolvedPlace resolvedPlace;
  final Map<String, dynamic> snapshot;

  factory ComputeChartResponse.fromJson(Map<String, dynamic> json) {
    return ComputeChartResponse(
      profile: _asMap(json['profile']),
      normalizedInput: _asMap(json['normalized_input']),
      resolvedPlace: ResolvedPlace.fromJson(_asMap(json['resolved_place'])),
      snapshot: _asMap(json['snapshot']),
    );
  }
}

class ResolvedPlace {
  const ResolvedPlace({
    required this.placeLabel,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.elevationM,
  });

  final String placeLabel;
  final double latitude;
  final double longitude;
  final String timezone;
  final double elevationM;

  CustomPlacePayload toCustomPlacePayload() {
    return CustomPlacePayload(
      placeLabel: placeLabel,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      elevationM: elevationM,
    );
  }

  factory ResolvedPlace.fromJson(Map<String, dynamic> json) {
    return ResolvedPlace(
      placeLabel: (json['place_label'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (json['timezone'] as String?) ?? '',
      elevationM: (json['elevation_m'] as num?)?.toDouble() ?? 0.0,
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
