import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/pancha_pakshi/data/models/pancha_pakshi_models.dart';
import 'package:trikaal_mobile/features/pancha_pakshi/presentation/state/pancha_pakshi_controller.dart';

void main() {
  group('PanchaPakshiController', () {
    test('load stores result and initializes countdown', () async {
      final apiClient = _FakeChartApiClient(
        response: _sampleResponse(secondsRemaining: 321),
      );
      final controller = PanchaPakshiController(apiClient: apiClient);

      await controller.load(
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Mumbai',
        runtimePlaceOfObservation: 'Detroit, Michigan, United States',
      );

      expect(controller.loading, isFalse);
      expect(controller.error, isNull);
      expect(controller.result, isNotNull);
      expect(controller.secondsRemaining, 321);
      expect(apiClient.computePanchaPakshiCalls, 1);
      expect(
        apiClient.lastRequest?.runtimePlaceOfObservation,
        'Detroit, Michigan, United States',
      );
      controller.dispose();
    });

    test('load failure stores user-facing error', () async {
      final apiClient = _FakeChartApiClient(
        exception: const ChartApiException('Place not found'),
      );
      final controller = PanchaPakshiController(apiClient: apiClient);

      await controller.load(
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Atlantis',
      );

      expect(controller.loading, isFalse);
      expect(controller.result, isNull);
      expect(controller.error, 'Place not found');
      expect(controller.secondsRemaining, 0);
      expect(apiClient.computePanchaPakshiCalls, 1);
      controller.dispose();
    });
  });
}

class _FakeChartApiClient extends ChartApiClient {
  _FakeChartApiClient({this.response, this.exception});

  final PanchaPakshiResponse? response;
  final Exception? exception;
  int computePanchaPakshiCalls = 0;
  PanchaPakshiRequest? lastRequest;

  @override
  Future<PanchaPakshiResponse> computePanchaPakshi(
    PanchaPakshiRequest request,
  ) async {
    computePanchaPakshiCalls += 1;
    lastRequest = request;
    if (exception != null) {
      throw exception!;
    }
    return response!;
  }
}

PanchaPakshiResponse _sampleResponse({required int secondsRemaining}) {
  return PanchaPakshiResponse(
    profile: const <String, dynamic>{
      'profile_id': 'vedic_lahiri_v1',
    },
    normalizedInput: const <String, dynamic>{
      'local_date': '1999-07-04',
      'local_time': '12:22',
      'place_query': 'Mumbai',
    },
    resolvedPlace: const <String, dynamic>{
      'place_label': 'Mumbai, Maharashtra, India',
      'timezone': 'Asia/Kolkata',
    },
    panchaPakshi: PanchaPakshiPayload(
      version: 'v1',
      birth: const PanchaPakshiBirth(
        nakshatraNumber: 25,
        nakshatraName: 'Purva Bhadrapada',
        paksha: 'Krishna',
        pakshi: 'Vulture',
      ),
      runtime: PanchaPakshiRuntime(
        asOfLocalIso: '2026-04-08T18:45:00+05:30',
        referencePlaceLabel: 'Mumbai, Maharashtra, India',
        referenceTimezone: 'Asia/Kolkata',
        weekday: 'Wednesday',
        paksha: 'Krishna',
        phase: 'night',
        phaseWindowStartLocalIso: '2026-04-08T18:40:00+05:30',
        phaseWindowEndLocalIso: '2026-04-09T06:10:00+05:30',
        nextTransitionLocalIso: '2026-04-08T19:00:00+05:30',
        secondsRemainingInActiveSubActivity: secondsRemaining,
      ),
      active: const PanchaPakshiActive(
        majorIndex: 2,
        mainBird: 'Vulture',
        mainActivity: 'Walking',
        subActivity: PanchaPakshiSubWindow(
          startLocalIso: '2026-04-08T18:45:00+05:30',
          endLocalIso: '2026-04-08T19:00:00+05:30',
          bird: 'Crow',
          activity: 'Eating',
          relation: 'Friend',
          effect: 'Good',
          powerFactor: 0.8,
          rating: 4,
          durationMinutes: 15,
        ),
      ),
      timeline: const <PanchaPakshiMajorWindow>[
        PanchaPakshiMajorWindow(
          majorIndex: 2,
          phase: 'night',
          paksha: 'Krishna',
          startLocalIso: '2026-04-08T18:40:00+05:30',
          endLocalIso: '2026-04-08T20:40:00+05:30',
          mainBird: 'Vulture',
          mainActivity: 'Walking',
          durationMinutes: 120,
          subTimeline: <PanchaPakshiSubWindow>[
            PanchaPakshiSubWindow(
              startLocalIso: '2026-04-08T18:45:00+05:30',
              endLocalIso: '2026-04-08T19:00:00+05:30',
              bird: 'Crow',
              activity: 'Eating',
              relation: 'Friend',
              effect: 'Good',
              powerFactor: 0.8,
              rating: 4,
              durationMinutes: 15,
            ),
          ],
        ),
      ],
    ),
  );
}
