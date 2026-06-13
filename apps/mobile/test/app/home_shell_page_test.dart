import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/home_shell_page.dart';
import 'package:trikaal_mobile/app/models/birth_session.dart';
import 'package:trikaal_mobile/app/models/custom_place_payload.dart';
import 'package:trikaal_mobile/app/models/person_gender.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_chart_models.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_report_models.dart';
import 'package:trikaal_mobile/features/home/presentation/home_overview_page.dart';
import 'package:trikaal_mobile/features/onboarding/presentation/onboarding_flow_page.dart';

import '../helpers/sample_report.dart';

const String _storageKey = 'trikaal_birth_session_v1';

// A pinned clock so the staleness decision is deterministic (no midnight race).
final DateTime _fixedNow = DateTime(2026, 6, 13, 9, 0);
final String _freshAsOf = DateTime(2026, 6, 13, 1, 0).toIso8601String();
final String _staleAsOf = DateTime(2026, 6, 11, 1, 0).toIso8601String();
// A distinctive timestamp the fake refresh returns, so the swap is observable.
const String _refreshedMarker = '2026-06-13T08:30:00.000';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpShell(
    WidgetTester tester, {
    ChartApiClient? chartApiClient,
    DateTime? now,
  }) async {
    // A generous surface so the populated home layout never reports overflow.
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeShellPage(chartApiClient: chartApiClient, now: now),
      ),
    );
  }

  testWidgets('shows the loading gate before the session is restored',
      (WidgetTester tester) async {
    await pumpShell(tester);

    // The first frame renders while restore is still in flight.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(OnboardingFlowPage), findsNothing);

    // Drain the gate for a clean teardown.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('falls back to onboarding when no session is persisted',
      (WidgetTester tester) async {
    await pumpShell(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(OnboardingFlowPage), findsOneWidget);
    expect(find.byType(HomeOverviewPage), findsNothing);
  });

  testWidgets('restores straight to home for a fresh persisted session',
      (WidgetTester tester) async {
    _seedSession(_reportJsonWithAsOf(_freshAsOf));
    final api = _FakeChartApiClient();
    addTearDown(api.dispose);

    await pumpShell(tester, chartApiClient: api, now: _fixedNow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(HomeOverviewPage), findsOneWidget);
    expect(find.byType(OnboardingFlowPage), findsNothing);
    // A same-day report is not refreshed.
    expect(api.computeReportCalls, 0);
  });

  testWidgets('refreshes a stale restored report and swaps it in',
      (WidgetTester tester) async {
    _seedSession(_reportJsonWithAsOf(_staleAsOf));
    final api = _FakeChartApiClient();
    addTearDown(api.dispose);

    await pumpShell(tester, chartApiClient: api, now: _fixedNow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Home is shown immediately from cache; the refresh runs once after.
    expect(find.byType(HomeOverviewPage), findsOneWidget);
    expect(api.computeReportCalls, 1);

    // The refreshed report is swapped in and re-persisted (proves the shell
    // called markReportComputed rather than just hitting the API).
    expect(await _persistedAsOf(), _refreshedMarker);
  });

  testWidgets('keeps the cached report when the refresh API is unreachable',
      (WidgetTester tester) async {
    _seedSession(_reportJsonWithAsOf(_staleAsOf));
    final api = _FakeChartApiClient(shouldThrow: true);
    addTearDown(api.dispose);

    await pumpShell(tester, chartApiClient: api, now: _fixedNow);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(api.computeReportCalls, 1);
    // The failed refresh does not knock the user back to onboarding.
    expect(find.byType(HomeOverviewPage), findsOneWidget);
    expect(find.byType(OnboardingFlowPage), findsNothing);
    // The stale-but-usable cached report is retained, not overwritten.
    expect(await _persistedAsOf(), _staleAsOf);
  });
}

Future<String?> _persistedAsOf() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_storageKey);
  if (raw == null) {
    return null;
  }
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final report = decoded['report'] as Map<String, dynamic>;
  final dasha = report['dasha'] as Map<String, dynamic>;
  return dasha['as_of_iso'] as String?;
}

Map<String, dynamic> _reportJsonWithAsOf(String asOfIso) {
  final report = sampleReportJson();
  final dasha = Map<String, dynamic>.from(report['dasha'] as Map);
  dasha['as_of_iso'] = asOfIso;
  report['dasha'] = dasha;
  return report;
}

void _seedSession(Map<String, dynamic> reportJson) {
  final session = BirthSession(
    onboardingCompleted: true,
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
    reportJson: reportJson,
  );
  SharedPreferences.setMockInitialValues(<String, Object>{
    _storageKey: jsonEncode(session.toJson()),
  });
}

class _FakeChartApiClient extends ChartApiClient {
  _FakeChartApiClient({this.shouldThrow = false});

  final bool shouldThrow;
  int computeReportCalls = 0;

  @override
  Future<ComputeReportResponse> computeReport(
    ComputeChartRequest request,
  ) async {
    computeReportCalls += 1;
    if (shouldThrow) {
      throw const ChartApiException('offline');
    }
    return ComputeReportResponse.fromJson(_reportJsonWithAsOf(_refreshedMarker));
  }

  @override
  void dispose() {}
}
