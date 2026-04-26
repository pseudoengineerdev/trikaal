import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/models/custom_place_payload.dart';
import 'package:trikaal_mobile/features/pancha_pakshi/data/models/pancha_pakshi_models.dart';

void main() {
  group('PanchaPakshiRequest', () {
    test('toJson includes optional runtime location fields', () {
      const request = PanchaPakshiRequest(
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Mumbai',
        runtimePlaceOfObservation: 'Detroit, Michigan, United States',
        runtimeCustomPlace: CustomPlacePayload(
          placeLabel: 'Detroit, Michigan, United States',
          latitude: 42.3314,
          longitude: -83.0458,
          timezone: 'America/Detroit',
          elevationM: 190.0,
        ),
      );

      final json = request.toJson();
      expect(
        json['runtime_place_of_observation'],
        'Detroit, Michigan, United States',
      );
      expect(
        json['runtime_custom_place'],
        isA<Map<String, dynamic>>(),
      );
    });
  });

  group('PanchaPakshiResponse', () {
    test('fromJson parses canonical payload shape', () {
      final parsed = PanchaPakshiResponse.fromJson(_samplePanchaPakshiJson());

      expect(parsed.profile['profile_id'], 'vedic_lahiri_v1');
      expect(parsed.resolvedPlace['timezone'], 'Asia/Kolkata');
      expect(parsed.panchaPakshi.birth.pakshi, 'Vulture');
      expect(parsed.panchaPakshi.active.mainActivity, 'Walking');
      expect(parsed.panchaPakshi.timeline, hasLength(1));
      expect(parsed.panchaPakshi.timeline.first.subTimeline, hasLength(1));
    });

    test('fromJson throws when timeline field is invalid', () {
      final broken = _samplePanchaPakshiJson();
      broken['pancha_pakshi'] = <String, dynamic>{
        ...(broken['pancha_pakshi']! as Map<String, dynamic>),
        'timeline': <String, dynamic>{},
      };

      expect(
        () => PanchaPakshiResponse.fromJson(broken),
        throwsFormatException,
      );
    });
  });
}

Map<String, dynamic> _samplePanchaPakshiJson() {
  return <String, dynamic>{
    'profile': <String, dynamic>{
      'profile_id': 'vedic_lahiri_v1',
      'zodiac_system': 'sidereal',
      'ayanamsha': 'lahiri_chitrapaksha',
      'calculation_method': 'modern_ephemeris',
    },
    'normalized_input': <String, dynamic>{
      'local_date': '1999-07-04',
      'local_time': '12:22',
      'place_query': 'Mumbai',
    },
    'resolved_place': <String, dynamic>{
      'place_label': 'Mumbai, Maharashtra, India',
      'latitude': 19.076,
      'longitude': 72.8777,
      'timezone': 'Asia/Kolkata',
      'elevation_m': 14.0,
    },
    'pancha_pakshi': <String, dynamic>{
      'version': 'v1',
      'birth': <String, dynamic>{
        'nakshatra_number': 25,
        'nakshatra_name': 'Purva Bhadrapada',
        'paksha': 'Krishna',
        'pakshi': 'Vulture',
      },
      'runtime': <String, dynamic>{
        'as_of_local_iso': '2026-04-08T18:45:00+05:30',
        'reference_place_label': 'Mumbai, Maharashtra, India',
        'reference_timezone': 'Asia/Kolkata',
        'weekday': 'Wednesday',
        'paksha': 'Krishna',
        'phase': 'night',
        'phase_window_start_local_iso': '2026-04-08T18:40:00+05:30',
        'phase_window_end_local_iso': '2026-04-09T06:10:00+05:30',
        'next_transition_local_iso': '2026-04-08T19:00:00+05:30',
        'seconds_remaining_in_active_sub_activity': 900,
      },
      'active': <String, dynamic>{
        'major_index': 2,
        'main_bird': 'Vulture',
        'main_activity': 'Walking',
        'sub_activity': <String, dynamic>{
          'start_local_iso': '2026-04-08T18:45:00+05:30',
          'end_local_iso': '2026-04-08T19:00:00+05:30',
          'bird': 'Crow',
          'activity': 'Eating',
          'relation': 'Friend',
          'effect': 'Good',
          'power_factor': 0.8,
          'rating': 4,
          'duration_minutes': 15.0,
        },
      },
      'timeline': <Map<String, dynamic>>[
        <String, dynamic>{
          'major_index': 2,
          'start_local_iso': '2026-04-08T18:40:00+05:30',
          'end_local_iso': '2026-04-08T20:40:00+05:30',
          'main_bird': 'Vulture',
          'main_activity': 'Walking',
          'duration_minutes': 120.0,
          'sub_timeline': <Map<String, dynamic>>[
            <String, dynamic>{
              'start_local_iso': '2026-04-08T18:45:00+05:30',
              'end_local_iso': '2026-04-08T19:00:00+05:30',
              'bird': 'Crow',
              'activity': 'Eating',
              'relation': 'Friend',
              'effect': 'Good',
              'power_factor': 0.8,
              'rating': 4,
              'duration_minutes': 15.0,
            },
          ],
        },
      ],
    },
  };
}
