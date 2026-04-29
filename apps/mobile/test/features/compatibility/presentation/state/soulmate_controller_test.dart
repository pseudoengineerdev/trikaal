import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_chart_models.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_compatibility_models.dart';
import 'package:trikaal_mobile/features/charts/data/models/place_search_models.dart';
import 'package:trikaal_mobile/features/compatibility/presentation/state/soulmate_controller.dart';

void main() {
  group('SoulmateController', () {
    test('compute success stores compatibility result', () async {
      final fakeApiClient = _FakeChartApiClient(
        compatibilityResponse: _sampleCompatibilityResponse(),
      );
      final controller = SoulmateController(apiClient: fakeApiClient);

      await controller.compute(
        primary: const CompatibilityPersonRequestPayload(
          dateOfBirth: '1999-07-04',
          timeOfBirth: '12:22',
          placeOfBirth: 'Mumbai',
        ),
        partner: const CompatibilityPersonRequestPayload(
          dateOfBirth: '2001-09-09',
          timeOfBirth: '01:30',
          placeOfBirth: 'New York',
        ),
        primaryRole: 'boy',
      );

      expect(controller.loading, isFalse);
      expect(controller.error, isNull);
      expect(controller.result, isNotNull);
      expect(controller.result!.compatibility.summary.gunaScore, 23.0);
      expect(fakeApiClient.computeCompatibilityCalls, 1);

      controller.dispose();
    });

    test('compute failure stores user-facing error', () async {
      final fakeApiClient = _FakeChartApiClient(
        computeException: const ChartApiException('Place not found'),
      );
      final controller = SoulmateController(apiClient: fakeApiClient);

      await controller.compute(
        primary: const CompatibilityPersonRequestPayload(
          dateOfBirth: '1999-07-04',
          timeOfBirth: '12:22',
          placeOfBirth: 'Mumbai',
        ),
        partner: const CompatibilityPersonRequestPayload(
          dateOfBirth: '2001-09-09',
          timeOfBirth: '01:30',
          placeOfBirth: 'Atlantis',
        ),
        primaryRole: 'boy',
      );

      expect(controller.loading, isFalse);
      expect(controller.result, isNull);
      expect(controller.error, 'Place not found');
      expect(fakeApiClient.computeCompatibilityCalls, 1);

      controller.dispose();
    });

    test('partner place query debounce fetches suggestions once', () async {
      final fakeApiClient = _FakeChartApiClient(
        compatibilityResponse: _sampleCompatibilityResponse(),
        placeSearchResponse: const PlaceSearchResponse(
          query: 'mum',
          count: 1,
          matches: <PlaceMatch>[
            PlaceMatch(
              placeLabel: 'Mumbai, Maharashtra, India',
              latitude: 19.076,
              longitude: 72.8777,
              timezone: 'Asia/Kolkata',
              elevationM: 14.0,
            ),
          ],
        ),
      );
      final controller = SoulmateController(apiClient: fakeApiClient);

      controller.onPartnerPlaceQueryChanged('mu');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      controller.onPartnerPlaceQueryChanged('mum');
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(fakeApiClient.searchCalls, 1);
      expect(controller.loadingPartnerPlaceSuggestions, isFalse);
      expect(controller.partnerPlaceSuggestions.length, 2);
      expect(controller.partnerPlaceSuggestions.first.placeLabel,
          'Mumbai, Maharashtra, India');
      expect(controller.partnerPlaceSuggestions.last.isCustom, isTrue);
      expect(controller.partnerPlaceSuggestions.last.placeLabel, 'mum');

      controller.dispose();
    });
  });
}

class _FakeChartApiClient extends ChartApiClient {
  _FakeChartApiClient({
    this.compatibilityResponse,
    this.placeSearchResponse,
    this.computeException,
  });

  final ComputeCompatibilityResponse? compatibilityResponse;
  final PlaceSearchResponse? placeSearchResponse;
  final Exception? computeException;

  int computeCompatibilityCalls = 0;
  int searchCalls = 0;

  @override
  Future<ComputeCompatibilityResponse> computeCompatibility(
    ComputeCompatibilityRequest request,
  ) async {
    computeCompatibilityCalls += 1;
    if (computeException != null) {
      throw computeException!;
    }
    return compatibilityResponse!;
  }

  @override
  Future<PlaceSearchResponse> searchPlaces(String query) async {
    searchCalls += 1;
    return placeSearchResponse ??
        const PlaceSearchResponse(
          query: '',
          count: 0,
          matches: <PlaceMatch>[],
        );
  }
}

ComputeCompatibilityResponse _sampleCompatibilityResponse() {
  return const ComputeCompatibilityResponse(
    profile: CompatibilityProfile(
      profileId: 'vedic_drik_lahiri_v1',
      zodiacSystem: 'sidereal',
      ayanamsha: 'lahiri_chitrapaksha',
      calculationMethod: 'drik_ganita',
    ),
    roles: CompatibilityRoleMap(primary: 'boy', partner: 'girl'),
    primary: CompatibilityPersonResolved(
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
    ),
    partner: CompatibilityPersonResolved(
      normalizedInput: <String, dynamic>{
        'local_date': '2001-09-09',
        'local_time': '01:30',
        'place_query': 'New York',
      },
      resolvedPlace: ResolvedPlace(
        placeLabel: 'New York, New York, United States',
        latitude: 40.7128,
        longitude: -74.006,
        timezone: 'America/New_York',
        elevationM: 10.0,
      ),
      snapshot: <String, dynamic>{},
    ),
    compatibility: CompatibilityResult(
      ashtaKuta: CompatibilityAshtaKuta(
        totalScore: 23.0,
        maxScore: 36.0,
        percentage: 63.89,
        classification: 'Very Good',
        components: <CompatibilityKutaComponent>[
          CompatibilityKutaComponent(
            key: 'varna',
            label: 'Varna',
            score: 0.0,
            maxScore: 1.0,
            percent: 0.0,
          ),
        ],
        nadiMatch: true,
        bhakootMatch: true,
      ),
      manglik: CompatibilityManglik(
        maxScore: 8.0,
        score: 8.0,
        pairAlignment: 'Balanced',
        verdict: 'Manglik profile aligned between both charts.',
        boy: CompatibilityManglikPerson(isManglik: true, triggerCount: 1),
        girl: CompatibilityManglikPerson(isManglik: true, triggerCount: 2),
      ),
      d1d9: <String, dynamic>{},
      summary: CompatibilitySummary(
        overallBand: 'Very Good',
        gunaScore: 23.0,
        gunaScoreMax: 36.0,
        manglikAlignment: 'Balanced',
        nadiMatch: true,
        bhakootMatch: true,
      ),
    ),
  );
}
