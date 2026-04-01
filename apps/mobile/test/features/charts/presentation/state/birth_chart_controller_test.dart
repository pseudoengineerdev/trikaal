import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_chart_models.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_report_models.dart';
import 'package:trikaal_mobile/features/charts/data/models/place_search_models.dart';
import 'package:trikaal_mobile/features/charts/presentation/state/birth_chart_controller.dart';
import 'package:trikaal_mobile/features/dasha/data/models/dasha_models.dart';

void main() {
  group('BirthChartController', () {
    test('submit success stores result and clears error', () async {
      final fakeApiClient = _FakeChartApiClient(
        computeReportResponse: _sampleComputeReportResponse(),
      );
      final controller = BirthChartController(apiClient: fakeApiClient);
      controller.placeSuggestions = <PlaceMatch>[
        const PlaceMatch(
          placeLabel: 'Mumbai, India',
          latitude: 19.076,
          longitude: 72.8777,
          timezone: 'Asia/Kolkata',
          elevationM: 14,
        ),
      ];

      await controller.submit(
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Mumbai',
      );

      expect(controller.loading, isFalse);
      expect(controller.error, isNull);
      expect(controller.result, isNotNull);
      expect(controller.dashaResult, isNotNull);
      expect(controller.placeSuggestions, isEmpty);
      expect(fakeApiClient.computeCalls, 1);

      controller.dispose();
    });

    test('submit failure stores user-facing error', () async {
      final fakeApiClient = _FakeChartApiClient(
        computeException: const ChartApiException('Place not found'),
      );
      final controller = BirthChartController(apiClient: fakeApiClient);

      await controller.submit(
        dateOfBirth: '1999-07-04',
        timeOfBirth: '12:22',
        placeOfBirth: 'Atlantis',
      );

      expect(controller.loading, isFalse);
      expect(controller.result, isNull);
      expect(controller.error, 'Place not found');
      expect(fakeApiClient.computeCalls, 1);

      controller.dispose();
    });

    test('short place query clears suggestions without API call', () {
      final fakeApiClient = _FakeChartApiClient(
        computeReportResponse: _sampleComputeReportResponse(),
      );
      final controller = BirthChartController(apiClient: fakeApiClient);
      controller.placeSuggestions = <PlaceMatch>[
        const PlaceMatch(
          placeLabel: 'Delhi, India',
          latitude: 28.6139,
          longitude: 77.2090,
          timezone: 'Asia/Kolkata',
          elevationM: 216,
        ),
      ];

      controller.onPlaceQueryChanged('m');

      expect(controller.placeSuggestions, isEmpty);
      expect(fakeApiClient.searchCalls, 0);

      controller.dispose();
    });

    test('debounced place query fetches suggestions once', () async {
      final fakeApiClient = _FakeChartApiClient(
        computeReportResponse: _sampleComputeReportResponse(),
        placeSearchResponse: const PlaceSearchResponse(
          query: 'mum',
          count: 1,
          matches: <PlaceMatch>[
            PlaceMatch(
              placeLabel: 'Mumbai, India',
              latitude: 19.076,
              longitude: 72.8777,
              timezone: 'Asia/Kolkata',
              elevationM: 14,
            ),
          ],
        ),
      );
      final controller = BirthChartController(apiClient: fakeApiClient);

      controller.onPlaceQueryChanged('mu');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      controller.onPlaceQueryChanged('mum');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fakeApiClient.searchCalls, 1);
      expect(controller.loadingPlaceSuggestions, isFalse);
      expect(controller.placeSuggestions.length, 2);
      expect(controller.placeSuggestions.first.placeLabel, 'Mumbai, India');
      expect(controller.placeSuggestions.last.isCustom, isTrue);
      expect(controller.placeSuggestions.last.placeLabel, 'mum');

      controller.dispose();
    });
  });
}

class _FakeChartApiClient extends ChartApiClient {
  _FakeChartApiClient({
    this.computeReportResponse,
    this.placeSearchResponse,
    this.computeException,
  });

  final ComputeReportResponse? computeReportResponse;
  final PlaceSearchResponse? placeSearchResponse;
  final Exception? computeException;

  int computeCalls = 0;
  int searchCalls = 0;

  @override
  Future<ComputeReportResponse> computeReport(
    ComputeChartRequest request,
  ) async {
    computeCalls += 1;
    if (computeException != null) {
      throw computeException!;
    }
    return computeReportResponse!;
  }

  @override
  Future<PlaceSearchResponse> searchPlaces(String query) async {
    searchCalls += 1;
    return placeSearchResponse ??
        const PlaceSearchResponse(query: '', count: 0, matches: <PlaceMatch>[]);
  }
}

ComputeReportResponse _sampleComputeReportResponse() {
  return const ComputeReportResponse(
    chart: ComputeChartResponse(
      profile: <String, dynamic>{
        'profile_id': 'vedic_lahiri_v1',
        'zodiac_system': 'sidereal',
        'ayanamsha': 'lahiri_chitrapaksha',
        'calculation_method': 'modern_ephemeris',
      },
      normalizedInput: <String, dynamic>{
        'local_date': '1999-07-04',
        'local_time': '12:22',
        'place_query': 'Mumbai',
      },
      resolvedPlace: ResolvedPlace(
        placeLabel: 'Mumbai, India',
        latitude: 19.076,
        longitude: 72.8777,
        timezone: 'Asia/Kolkata',
        elevationM: 14,
      ),
      snapshot: <String, dynamic>{
        'meta': <String, dynamic>{'status': 'computed'},
        'vedic': <String, dynamic>{'lagna_rashi': 'Kany'},
      },
    ),
    dasha: DashaSummary(
      system: 'Vimshottari',
      currentMahaDasha: 'Ketu',
      currentAntarDasha: 'Rahu',
      activeFrom: '2025-01-01T00:00:00Z',
      activeUntil: '2026-01-01T00:00:00Z',
      currentMahaStart: '2024-01-01T00:00:00Z',
      currentMahaEnd: '2031-01-01T00:00:00Z',
      mahaTimeline: <DashaPeriod>[],
      antarTimelineCurrentMaha: <DashaPeriod>[],
    ),
  );
}
