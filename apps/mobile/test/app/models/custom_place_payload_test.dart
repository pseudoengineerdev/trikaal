import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/models/custom_place_payload.dart';

void main() {
  group('CustomPlacePayload', () {
    test('toJson sanitizes non-finite numbers', () {
      final payload = CustomPlacePayload(
        placeLabel: 'Sample',
        latitude: double.nan,
        longitude: double.infinity,
        timezone: 'UTC',
        elevationM: double.negativeInfinity,
      );

      final json = payload.toJson();
      expect(json['latitude'], 0.0);
      expect(json['longitude'], 0.0);
      expect(json['elevation_m'], 0.0);
    });

    test('fromJson sanitizes non-finite numbers', () {
      final parsed = CustomPlacePayload.fromJson(
        <String, dynamic>{
          'place_label': 'Sample',
          'latitude': double.nan,
          'longitude': double.infinity,
          'timezone': 'UTC',
          'elevation_m': double.negativeInfinity,
        },
      );

      expect(parsed.latitude, 0.0);
      expect(parsed.longitude, 0.0);
      expect(parsed.elevationM, 0.0);
    });
  });
}
