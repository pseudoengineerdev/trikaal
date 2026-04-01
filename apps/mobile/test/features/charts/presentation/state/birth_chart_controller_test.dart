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

    test('applyComputedResult hydrates controller without API call', () {
      final fakeApiClient = _FakeChartApiClient(
        computeReportResponse: _sampleComputeReportResponse(),
      );
      final controller = BirthChartController(apiClient: fakeApiClient);
      controller.error = 'old';
      controller.loading = true;

      controller.applyComputedResult(
        report: _sampleComputeReportResponse(),
        dasha: _sampleComputeReportResponse().dasha,
      );

      expect(controller.loading, isFalse);
      expect(controller.error, isNull);
      expect(controller.result, isNotNull);
      expect(controller.dashaResult, isNotNull);
      expect(fakeApiClient.computeCalls, 0);

      controller.dispose();
    });

    test('clearComputedResult removes cached report and dasha', () {
      final fakeApiClient = _FakeChartApiClient(
        computeReportResponse: _sampleComputeReportResponse(),
      );
      final controller = BirthChartController(apiClient: fakeApiClient);
      controller.result = _sampleComputeReportResponse();
      controller.dashaResult = _sampleComputeReportResponse().dasha;

      controller.clearComputedResult();

      expect(controller.result, isNull);
      expect(controller.dashaResult, isNull);
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
    profile: ReportProfile(
      profileId: 'vedic_drik_lahiri_v1',
      zodiacSystem: 'sidereal',
      ayanamsha: 'lahiri_chitrapaksha',
      calculationMethod: 'drik_ganita',
    ),
    normalizedInput: ReportNormalizedInput(
      localDate: '1999-07-04',
      localTime: '12:22',
      placeQuery: 'Mumbai',
    ),
    resolvedPlace: ResolvedPlace(
      placeLabel: 'Mumbai, India',
      latitude: 19.076,
      longitude: 72.8777,
      timezone: 'Asia/Kolkata',
      elevationM: 14,
    ),
    snapshot: ReportSnapshot(
      meta: ReportSnapshotMeta(
        status: 'computed',
        profileId: 'vedic_drik_lahiri_v1',
        timezone: 'Asia/Kolkata',
        utcIso: '1999-07-04T06:52:00+00:00',
      ),
      panchanga: ReportPanchanga(
        vara: ReportVara(
          number: 1,
          nameVedic: 'Ravivara',
          nameEnglish: 'Sunday',
        ),
        tithi: ReportTithi(
          number: 21,
          paksha: 'Krishna',
          pakshaEnglish: 'Waning',
          nameVedic: 'Krishna Shashthi',
          nameEnglish: 'Waning Shashthi',
          progressPercent: 30.0,
        ),
        nakshatra: ReportNakshatra(
          number: 25,
          nameVedic: 'P Bhadrapada',
          nameEnglish: 'Purva Bhadrapada',
          pada: 1,
          progressPercent: 4.0,
        ),
        yoga: ReportYoga(
          number: 3,
          nameVedic: 'Ayushman',
          nameEnglish: 'Ayushman',
          progressPercent: 11.0,
        ),
        karana: ReportKarana(
          serial: 55,
          nameVedic: 'Garija',
          nameEnglish: 'Garija',
          progressPercent: 64.0,
        ),
        sunrise: ReportSolarEvent(
          utcIso: '1999-07-04T00:33:00+00:00',
          localIso: '1999-07-04T06:03:00+05:30',
          localTime: '06:03',
        ),
        sunset: ReportSolarEvent(
          utcIso: '1999-07-04T13:43:00+00:00',
          localIso: '1999-07-04T19:13:00+05:30',
          localTime: '19:13',
        ),
      ),
      astronomy: ReportAstronomy(
        julianDayUtc: 0,
        drikDisplayOffsetDeg: 0,
        drikLagnaDisplayOffsetDeg: 0,
        sunSiderealDeg: 0,
        sunSiderealDegRaw: 0,
        moonSiderealDeg: 0,
        moonSiderealDegRaw: 0,
        mangalSiderealDeg: 0,
        mangalSiderealDegRaw: 0,
        budhaSiderealDeg: 0,
        budhaSiderealDegRaw: 0,
        guruSiderealDeg: 0,
        guruSiderealDegRaw: 0,
        shukraSiderealDeg: 0,
        shukraSiderealDegRaw: 0,
        shaniSiderealDeg: 0,
        shaniSiderealDegRaw: 0,
        rahuSiderealDeg: 0,
        rahuSiderealDegRaw: 0,
        ketuSiderealDeg: 0,
        ketuSiderealDegRaw: 0,
        spashthRahuSiderealDeg: 0,
        spashthRahuSiderealDegRaw: 0,
        spashthKetuSiderealDeg: 0,
        spashthKetuSiderealDegRaw: 0,
        lagnaSiderealDeg: 0,
        lagnaSiderealDegRaw: 0,
      ),
      vedic: ReportVedic(
        sun: ReportVedicGraha(rashi: 'Mitu', nakshatra: 'Ardra', pada: 4),
        moon:
            ReportVedicGraha(rashi: 'Kumb', nakshatra: 'P Bhadrapada', pada: 1),
        lagna: ReportVedicGraha(rashi: 'Kany', nakshatra: 'Hasta', pada: 2),
        mangal: ReportVedicGraha(rashi: 'Tula', nakshatra: 'Chitra', pada: 4),
        budha: ReportVedicGraha(rashi: 'Kark', nakshatra: 'Pushya', pada: 3),
        guru: ReportVedicGraha(rashi: 'Mesh', nakshatra: 'Ashwini', pada: 3),
        shukra: ReportVedicGraha(rashi: 'Simh', nakshatra: 'Magha', pada: 1),
        shani: ReportVedicGraha(rashi: 'Mesh', nakshatra: 'Bharani', pada: 3),
        rahu: ReportVedicGraha(rashi: 'Kark', nakshatra: 'Ashlesha', pada: 2),
        ketu: ReportVedicGraha(rashi: 'Maka', nakshatra: 'Shravana', pada: 4),
        spashthRahu:
            ReportVedicGraha(rashi: 'Kark', nakshatra: 'Ashlesha', pada: 1),
        spashthKetu:
            ReportVedicGraha(rashi: 'Maka', nakshatra: 'Shravana', pada: 3),
      ),
      bhava: ReportBhava(
        lagnaHouse: 1,
        sunHouse: 10,
        moonHouse: 6,
        mangalHouse: 2,
        budhaHouse: 11,
        guruHouse: 8,
        shukraHouse: 12,
        shaniHouse: 8,
        rahuHouse: 11,
        ketuHouse: 5,
        spashthRahuHouse: 11,
        spashthKetuHouse: 5,
      ),
      varga: ReportVarga(
        d1: ReportDivision(
          lagnaRashi: 'Kany',
          houses: <int, ReportHouse>{
            1: ReportHouse(rashi: 'Kany', occupants: <String>['lagna']),
            2: ReportHouse(rashi: 'Tula', occupants: <String>[]),
            3: ReportHouse(rashi: 'Vrsc', occupants: <String>[]),
            4: ReportHouse(rashi: 'Dhanu', occupants: <String>[]),
            5: ReportHouse(rashi: 'Maka', occupants: <String>['ketu']),
            6: ReportHouse(rashi: 'Kumb', occupants: <String>['moon']),
            7: ReportHouse(rashi: 'Meen', occupants: <String>[]),
            8: ReportHouse(rashi: 'Mesh', occupants: <String>['guru', 'shani']),
            9: ReportHouse(rashi: 'Vrish', occupants: <String>[]),
            10: ReportHouse(rashi: 'Mitu', occupants: <String>['sun']),
            11: ReportHouse(
                rashi: 'Kark', occupants: <String>['budha', 'rahu']),
            12: ReportHouse(rashi: 'Simh', occupants: <String>['shukra']),
          },
        ),
        d9: ReportDivision(
          lagnaRashi: 'Maka',
          houses: <int, ReportHouse>{
            1: ReportHouse(rashi: 'Maka', occupants: <String>['lagna']),
            2: ReportHouse(rashi: 'Kumb', occupants: <String>[]),
            3: ReportHouse(rashi: 'Meen', occupants: <String>['sun']),
            4: ReportHouse(rashi: 'Mesh', occupants: <String>[]),
            5: ReportHouse(rashi: 'Vrish', occupants: <String>[]),
            6: ReportHouse(rashi: 'Mitu', occupants: <String>['moon']),
            7: ReportHouse(rashi: 'Kark', occupants: <String>[]),
            8: ReportHouse(rashi: 'Simh', occupants: <String>[]),
            9: ReportHouse(rashi: 'Kany', occupants: <String>[]),
            10: ReportHouse(rashi: 'Tula', occupants: <String>['ketu']),
            11: ReportHouse(rashi: 'Vrsc', occupants: <String>[]),
            12: ReportHouse(rashi: 'Dhanu', occupants: <String>['rahu']),
          },
        ),
      ),
      grahaTable: ReportGrahaTable(
        sun: ReportGrahaEntry(
          key: 'sun',
          siderealDeg: 78.0,
          siderealDegRaw: 78.0,
          speedDegPerDay: 1.0,
          rashi: 'Mitu',
          nakshatra: 'Ardra',
          pada: 4,
          house: 10,
          d9Rashi: 'Meen',
          d9House: 3,
          retrograde: false,
          combust: false,
        ),
        moon: ReportGrahaEntry(
          key: 'moon',
          siderealDeg: 320.0,
          siderealDegRaw: 320.0,
          speedDegPerDay: 13.0,
          rashi: 'Kumb',
          nakshatra: 'P Bhadrapada',
          pada: 1,
          house: 6,
          d9Rashi: 'Mitu',
          d9House: 6,
          retrograde: false,
          combust: false,
        ),
        mangal: ReportGrahaEntry(
          key: 'mangal',
          siderealDeg: 185.0,
          siderealDegRaw: 185.0,
          speedDegPerDay: 0.5,
          rashi: 'Tula',
          nakshatra: 'Chitra',
          pada: 4,
          house: 2,
          d9Rashi: 'Kark',
          d9House: 7,
          retrograde: false,
          combust: false,
        ),
        budha: ReportGrahaEntry(
          key: 'budha',
          siderealDeg: 102.0,
          siderealDegRaw: 102.0,
          speedDegPerDay: 1.3,
          rashi: 'Kark',
          nakshatra: 'Pushya',
          pada: 3,
          house: 11,
          d9Rashi: 'Kany',
          d9House: 9,
          retrograde: false,
          combust: false,
        ),
        guru: ReportGrahaEntry(
          key: 'guru',
          siderealDeg: 7.0,
          siderealDegRaw: 7.0,
          speedDegPerDay: 0.1,
          rashi: 'Mesh',
          nakshatra: 'Ashwini',
          pada: 3,
          house: 8,
          d9Rashi: 'Maka',
          d9House: 1,
          retrograde: false,
          combust: false,
        ),
        shukra: ReportGrahaEntry(
          key: 'shukra',
          siderealDeg: 120.0,
          siderealDegRaw: 120.0,
          speedDegPerDay: 1.1,
          rashi: 'Simh',
          nakshatra: 'Magha',
          pada: 1,
          house: 12,
          d9Rashi: 'Tula',
          d9House: 10,
          retrograde: false,
          combust: true,
        ),
        shani: ReportGrahaEntry(
          key: 'shani',
          siderealDeg: 20.0,
          siderealDegRaw: 20.0,
          speedDegPerDay: 0.05,
          rashi: 'Mesh',
          nakshatra: 'Bharani',
          pada: 3,
          house: 8,
          d9Rashi: 'Kumb',
          d9House: 2,
          retrograde: true,
          combust: false,
        ),
        rahu: ReportGrahaEntry(
          key: 'rahu',
          siderealDeg: 110.0,
          siderealDegRaw: 110.0,
          speedDegPerDay: -0.05,
          rashi: 'Kark',
          nakshatra: 'Ashlesha',
          pada: 2,
          house: 11,
          d9Rashi: 'Dhanu',
          d9House: 12,
          retrograde: true,
          combust: false,
        ),
        ketu: ReportGrahaEntry(
          key: 'ketu',
          siderealDeg: 290.0,
          siderealDegRaw: 290.0,
          speedDegPerDay: 0.0,
          rashi: 'Maka',
          nakshatra: 'Shravana',
          pada: 4,
          house: 5,
          d9Rashi: 'Mitu',
          d9House: 6,
          retrograde: true,
          combust: false,
        ),
        spashthRahu: ReportGrahaEntry(
          key: 'spashth_rahu',
          siderealDeg: 109.0,
          siderealDegRaw: 109.0,
          speedDegPerDay: -0.04,
          rashi: 'Kark',
          nakshatra: 'Ashlesha',
          pada: 1,
          house: 11,
          d9Rashi: 'Dhanu',
          d9House: 12,
          retrograde: true,
          combust: false,
        ),
        spashthKetu: ReportGrahaEntry(
          key: 'spashth_ketu',
          siderealDeg: 289.0,
          siderealDegRaw: 289.0,
          speedDegPerDay: 0.0,
          rashi: 'Maka',
          nakshatra: 'Shravana',
          pada: 3,
          house: 5,
          d9Rashi: 'Mitu',
          d9House: 6,
          retrograde: true,
          combust: false,
        ),
        lagna: ReportGrahaEntry(
          key: 'lagna',
          siderealDeg: 163.0,
          siderealDegRaw: 163.0,
          speedDegPerDay: 0.0,
          rashi: 'Kany',
          nakshatra: 'Hasta',
          pada: 2,
          house: 1,
          d9Rashi: 'Maka',
          d9House: 1,
          retrograde: false,
          combust: false,
        ),
      ),
    ),
    dasha: DashaSummary(
      system: 'Vimshottari',
      asOfIso: '2026-01-01T00:00:00Z',
      birthMoonNakshatra: 'P Bhadrapada',
      currentMahaDasha: 'Ketu',
      currentAntarDasha: 'Rahu',
      activeFrom: '2025-01-01T00:00:00Z',
      activeUntil: '2026-01-01T00:00:00Z',
      currentMahaStart: '2024-01-01T00:00:00Z',
      currentMahaEnd: '2031-01-01T00:00:00Z',
      mahaTimeline: <DashaPeriod>[],
      antarTimelineCurrentMaha: <DashaPeriod>[],
    ),
    interpretations: ReportInterpretations(
      version: 'v1',
      cards: <ReportInterpretationCard>[
        ReportInterpretationCard(
          cardId: 'yoga_budha_aditya',
          category: 'yoga',
          confidence: 'high',
          strengthScore: 0.86,
          title: ReportLocalizedText(
            english: 'Budha-Aditya Yoga pattern detected',
            vedic: 'Budha-Aditya yoga pattern detected',
          ),
          summary: ReportLocalizedText(
            english: 'Sun and Mercury are in the same house.',
            vedic: 'Surya and Budha are in the same bhava.',
          ),
          impact: ReportLocalizedText(
            english: 'This can support clear expression and planning.',
            vedic: 'This can support buddhi and articulate speech.',
          ),
          evidence: <ReportLocalizedText>[
            ReportLocalizedText(
              english: 'Sun and Mercury both occupy H10.',
              vedic: 'Surya and Budha both occupy 10th Bhava.',
            ),
          ],
        ),
      ],
    ),
  );
}
