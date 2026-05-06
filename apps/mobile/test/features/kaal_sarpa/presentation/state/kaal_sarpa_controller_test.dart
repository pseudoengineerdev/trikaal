import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_chart_models.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_kaal_sarpa_models.dart';
import 'package:trikaal_mobile/features/kaal_sarpa/presentation/state/kaal_sarpa_controller.dart';

void main() {
  group('KaalSarpaController', () {
    test('compute success stores result', () async {
      final fakeApiClient = _FakeChartApiClient(
        response: _sampleKaalSarpaResponse(),
      );
      final controller = KaalSarpaController(apiClient: fakeApiClient);

      await controller.compute(
        request: const ComputeKaalSarpaRequest(
          dateOfBirth: '1999-07-04',
          timeOfBirth: '12:22',
          placeOfBirth: 'Mumbai',
        ),
      );

      expect(controller.loading, isFalse);
      expect(controller.error, isNull);
      expect(controller.result, isNotNull);
      expect(controller.result!.kaalSarpa.ruleProfileId, 'kaal_sarpa_dosha_v1');
      expect(fakeApiClient.computeKaalSarpaCalls, 1);

      controller.dispose();
    });

    test('compute failure stores user-facing error', () async {
      final fakeApiClient = _FakeChartApiClient(
        exception: const ChartApiException('Place not found'),
      );
      final controller = KaalSarpaController(apiClient: fakeApiClient);

      await controller.compute(
        request: const ComputeKaalSarpaRequest(
          dateOfBirth: '1999-07-04',
          timeOfBirth: '12:22',
          placeOfBirth: 'Atlantis',
        ),
      );

      expect(controller.loading, isFalse);
      expect(controller.result, isNull);
      expect(controller.error, 'Place not found');
      expect(fakeApiClient.computeKaalSarpaCalls, 1);

      controller.dispose();
    });
  });
}

class _FakeChartApiClient extends ChartApiClient {
  _FakeChartApiClient({
    this.response,
    this.exception,
  });

  final ComputeKaalSarpaResponse? response;
  final Exception? exception;

  int computeKaalSarpaCalls = 0;

  @override
  Future<ComputeKaalSarpaResponse> computeKaalSarpa(
    ComputeKaalSarpaRequest request,
  ) async {
    computeKaalSarpaCalls += 1;
    if (exception != null) {
      throw exception!;
    }
    return response!;
  }
}

ComputeKaalSarpaResponse _sampleKaalSarpaResponse() {
  return const ComputeKaalSarpaResponse(
    profile: <String, dynamic>{
      'profile_id': 'vedic_lahiri_v1',
    },
    normalizedInput: <String, dynamic>{
      'local_date': '1999-07-04',
      'local_time': '12:22',
      'place_query': 'Mumbai',
    },
    resolvedPlace: ResolvedPlace(
      placeLabel: 'Mumbai, Maharashtra, India',
      latitude: 19.076,
      longitude: 72.8777,
      timezone: 'Asia/Kolkata',
      elevationM: 14.0,
    ),
    snapshot: <String, dynamic>{},
    kaalSarpa: KaalSarpaResult(
      ruleProfileId: 'kaal_sarpa_dosha_v1',
      method: 'all_seven_classical_planets_within_rahu_ketu_axis_no_partial',
      isKaalSarpa: false,
      kaalSarpaType: '',
      rahuHouse: 11,
      ketuHouse: 5,
      enclosedSide: 'rahu_to_ketu_candidate',
      outsidePlanets: <String>['moon'],
      outsidePlanetCount: 1,
      axis: KaalSarpaAxisEvidence(
        rahuDegree: 110.0,
        ketuDegree: 290.0,
        rahuToKetuEnclosure: false,
        ketuToRahuEnclosure: false,
      ),
      classicalPlanets: <String>[
        'sun',
        'moon',
        'mangal',
        'budha',
        'guru',
        'shukra',
        'shani',
      ],
      planetEvidence: <String, KaalSarpaPlanetEvidence>{
        'sun': KaalSarpaPlanetEvidence(
          siderealDegree: 78.02,
          withinRahuToKetuArc: true,
          withinKetuToRahuArc: false,
        ),
      },
      verdict: 'No Kaal Sarpa Dosha.',
    ),
  );
}
