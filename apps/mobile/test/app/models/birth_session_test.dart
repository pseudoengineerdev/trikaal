import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/models/birth_session.dart';
import 'package:trikaal_mobile/app/models/custom_place_payload.dart';
import 'package:trikaal_mobile/app/models/person_gender.dart';

void main() {
  group('BirthSession serialization', () {
    test('survives a jsonEncode/decode round-trip', () {
      const session = BirthSession(
        onboardingCompleted: true,
        firstName: 'Asha',
        gender: PersonGender.female,
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Mumbai, Maharashtra, India',
        customPlace: CustomPlacePayload(
          placeLabel: 'Mumbai, Maharashtra, India',
          latitude: 19.076,
          longitude: 72.8777,
          timezone: 'Asia/Kolkata',
          elevationM: 14,
        ),
        reportJson: <String, dynamic>{
          'dasha': <String, dynamic>{'as_of_iso': '2026-06-13T01:15:00+05:30'},
          'nested': <String, dynamic>{'value': 7},
        },
      );

      final decoded = jsonDecode(jsonEncode(session.toJson()));
      final restored = BirthSession.fromJson(
        (decoded as Map).map(
          (dynamic key, dynamic value) => MapEntry(key.toString(), value),
        ),
      );

      expect(restored.onboardingCompleted, isTrue);
      expect(restored.firstName, 'Asha');
      expect(restored.gender, PersonGender.female);
      expect(restored.dateOfBirth, '1999-07-04');
      expect(restored.timeOfBirth, '12:22');
      expect(restored.placeOfBirth, 'Mumbai, Maharashtra, India');
      expect(restored.customPlace!.timezone, 'Asia/Kolkata');
      expect(restored.customPlace!.latitude, 19.076);
      expect(
        (restored.reportJson['nested'] as Map)['value'],
        7,
      );
    });

    test('tolerates a missing custom place', () {
      const session = BirthSession(
        onboardingCompleted: false,
        firstName: '',
        gender: PersonGender.unspecified,
        dateOfBirth: '2001-01-01',
        timeOfBirth: '06:00',
        placeOfBirth: 'Unknown',
        customPlace: null,
        reportJson: <String, dynamic>{'dasha': <String, dynamic>{}},
      );

      final restored = BirthSession.fromJson(session.toJson());

      expect(restored.customPlace, isNull);
      expect(restored.onboardingCompleted, isFalse);
      expect(restored.gender, PersonGender.unspecified);
    });

    test('throws when the report payload is not an object', () {
      expect(
        () => BirthSession.fromJson(<String, dynamic>{
          'onboarding_completed': true,
          'report': 'not-a-map',
        }),
        throwsFormatException,
      );
    });
  });
}
