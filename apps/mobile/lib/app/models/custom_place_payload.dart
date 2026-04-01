class CustomPlacePayload {
  const CustomPlacePayload({
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

  CustomPlacePayload sanitized() {
    return CustomPlacePayload(
      placeLabel: placeLabel.trim(),
      latitude: _finiteOrZero(latitude),
      longitude: _finiteOrZero(longitude),
      timezone: timezone.trim(),
      elevationM: _finiteOrZero(elevationM),
    );
  }

  factory CustomPlacePayload.fromJson(Map<String, dynamic> json) {
    return CustomPlacePayload(
      placeLabel: (json['place_label'] as String?) ?? '',
      latitude: _asFiniteDouble(json['latitude']),
      longitude: _asFiniteDouble(json['longitude']),
      timezone: (json['timezone'] as String?) ?? '',
      elevationM: _asFiniteDouble(json['elevation_m']),
    );
  }

  Map<String, dynamic> toJson() {
    final safe = sanitized();
    return <String, dynamic>{
      'place_label': safe.placeLabel,
      'latitude': safe.latitude,
      'longitude': safe.longitude,
      'timezone': safe.timezone,
      'elevation_m': safe.elevationM,
    };
  }

  static double _asFiniteDouble(Object? value) {
    final parsed = (value as num?)?.toDouble() ?? 0.0;
    return _finiteOrZero(parsed);
  }

  static double _finiteOrZero(double value) {
    if (!value.isFinite) {
      return 0.0;
    }
    return value;
  }
}
