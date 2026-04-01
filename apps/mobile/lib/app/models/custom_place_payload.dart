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

  factory CustomPlacePayload.fromJson(Map<String, dynamic> json) {
    return CustomPlacePayload(
      placeLabel: (json['place_label'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (json['timezone'] as String?) ?? '',
      elevationM: (json['elevation_m'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'place_label': placeLabel,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'elevation_m': elevationM,
    };
  }
}
