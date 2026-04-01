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
