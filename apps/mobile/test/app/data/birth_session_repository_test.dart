import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/data/birth_session_repository.dart';
import 'package:trikaal_mobile/app/models/birth_session.dart';
import 'package:trikaal_mobile/app/models/custom_place_payload.dart';
import 'package:trikaal_mobile/app/models/person_gender.dart';

const String _storageKey = 'trikaal_birth_session_v1';

BirthSession _session({
  bool onboardingCompleted = true,
  Map<String, dynamic>? reportJson,
}) {
  return BirthSession(
    onboardingCompleted: onboardingCompleted,
    firstName: 'Asha',
    gender: PersonGender.female,
    dateOfBirth: '1999-07-04',
    timeOfBirth: '12:22',
    placeOfBirth: 'Mumbai, Maharashtra, India',
    customPlace: const CustomPlacePayload(
      placeLabel: 'Mumbai, Maharashtra, India',
      latitude: 19.076,
      longitude: 72.8777,
      timezone: 'Asia/Kolkata',
      elevationM: 14,
    ),
    reportJson: reportJson ??
        <String, dynamic>{
          'dasha': <String, dynamic>{
            'as_of_iso': '2026-06-13T01:15:00+05:30',
          },
          'note': 'sample',
        },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesBirthSessionRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('round-trips a saved session under the versioned key', () async {
      final repository = SharedPreferencesBirthSessionRepository();

      await repository.saveSession(_session());
      final restored = await repository.loadSession();

      expect(restored, isNotNull);
      expect(restored!.onboardingCompleted, isTrue);
      expect(restored.firstName, 'Asha');
      expect(restored.gender, PersonGender.female);
      expect(restored.dateOfBirth, '1999-07-04');
      expect(restored.timeOfBirth, '12:22');
      expect(restored.placeOfBirth, 'Mumbai, Maharashtra, India');
      expect(restored.customPlace, isNotNull);
      expect(restored.customPlace!.timezone, 'Asia/Kolkata');
      expect(restored.reportJson['note'], 'sample');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_storageKey), isNotNull);
    });

    test('loadSession returns null when nothing is stored', () async {
      final repository = SharedPreferencesBirthSessionRepository();

      expect(await repository.loadSession(), isNull);
    });

    test('loadSession returns null for corrupt JSON', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        _storageKey: 'not-valid-json{',
      });
      final repository = SharedPreferencesBirthSessionRepository();

      expect(await repository.loadSession(), isNull);
    });

    test('loadSession returns null when the report payload is missing',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        _storageKey: jsonEncode(<String, dynamic>{
          'onboarding_completed': true,
          'first_name': 'Asha',
        }),
      });
      final repository = SharedPreferencesBirthSessionRepository();

      expect(await repository.loadSession(), isNull);
    });

    test('clearSession removes the stored session', () async {
      final repository = SharedPreferencesBirthSessionRepository();
      await repository.saveSession(_session());

      await repository.clearSession();

      expect(await repository.loadSession(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_storageKey), isNull);
    });

    test('falls back to memory when SharedPreferences is unavailable',
        () async {
      final repository = SharedPreferencesBirthSessionRepository(
        prefsLoader: () async => throw Exception('prefs unavailable'),
      );

      await repository.saveSession(_session());
      final restored = await repository.loadSession();

      expect(restored, isNotNull);
      expect(restored!.firstName, 'Asha');
    });
  });
}
