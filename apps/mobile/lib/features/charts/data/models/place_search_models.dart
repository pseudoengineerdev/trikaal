class PlaceSearchResponse {
  const PlaceSearchResponse({
    required this.query,
    required this.count,
    required this.matches,
  });

  final String query;
  final int count;
  final List<PlaceMatch> matches;

  factory PlaceSearchResponse.fromJson(Map<String, dynamic> json) {
    final rawMatches = (json['matches'] as List<dynamic>?) ?? const <dynamic>[];
    return PlaceSearchResponse(
      query: (json['query'] as String?) ?? '',
      count: (json['count'] as int?) ?? 0,
      matches: rawMatches
          .map((item) => PlaceMatch.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }
}

class PlaceMatch {
  const PlaceMatch({
    required this.placeLabel,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.elevationM,
    this.isCustom = false,
  });

  final String placeLabel;
  final double latitude;
  final double longitude;
  final String timezone;
  final double elevationM;
  final bool isCustom;

  factory PlaceMatch.fromJson(Map<String, dynamic> json) {
    return PlaceMatch(
      placeLabel: (json['place_label'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (json['timezone'] as String?) ?? '',
      elevationM: (json['elevation_m'] as num?)?.toDouble() ?? 0.0,
      isCustom: (json['is_custom'] as bool?) ?? false,
    );
  }

  factory PlaceMatch.custom(String rawQuery) {
    return PlaceMatch(
      placeLabel: rawQuery,
      latitude: 0.0,
      longitude: 0.0,
      timezone: 'Resolve automatically at compute time',
      elevationM: 0.0,
      isCustom: true,
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
