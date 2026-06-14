import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/app/state/terminology_mode_state.dart';
import 'package:trikaal_mobile/app/theme/trikaal_theme.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/gochar/presentation/gochar_page.dart';
import 'package:trikaal_mobile/features/gochar/presentation/state/gochar_controller.dart';

import '../../../helpers/sample_transit.dart';

DateTime _fixedNow() => DateTime(2026, 6, 14, 12, 0);

BirthInputState _birthInputState() {
  return BirthInputState(
    firstName: 'Sahil',
    dateOfBirth: '1995-03-21',
    timeOfBirth: '22:10',
    placeOfBirth: 'Mumbai',
  );
}

GocharController _mockController(List<String?> requestedDates) {
  final mockClient = MockClient((http.Request request) async {
    final payload = jsonDecode(request.body) as Map<String, dynamic>;
    final date = payload['as_of_date'] as String?;
    requestedDates.add(date);
    return http.Response(
      jsonEncode(sampleTransitResponseJson(date ?? '2026-06-14')),
      200,
      headers: <String, String>{'Content-Type': 'application/json'},
    );
  });
  return GocharController(
    apiClient:
        ChartApiClient(baseUrl: 'http://localhost:1', httpClient: mockClient),
    now: _fixedNow,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required BirthInputState birthInputState,
  GocharController? controller,
}) async {
  tester.view.physicalSize = const Size(1080, 12000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TrikaalTheme.dark(),
      home: GocharPage(
        birthInputState: birthInputState,
        controller: controller,
        now: _fixedNow,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    TerminologyModeState.shared.setMode(TerminologyMode.vedic);
  });

  testWidgets('renders the transit overview, Sade Sati and planet rows',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final requestedDates = <String?>[];
    final controller = _mockController(requestedDates);
    addTearDown(controller.dispose);

    await _pump(tester, birthInputState: birthInputState, controller: controller);

    expect(requestedDates, contains('2026-06-14'));
    expect(find.text('Planet Transits'), findsOneWidget);
    expect(find.text('Sade Sati'), findsOneWidget);
    expect(find.text('From Moon'), findsOneWidget);
    expect(find.text('From Lagna'), findsOneWidget);
    // Planet rows render in Sanskrit (terminology = vedic).
    expect(find.text('Shani'), findsOneWidget);
    expect(find.text('Guru'), findsOneWidget);
    // Default frame labels the Moon house column.
    expect(find.text('House from Moon'), findsOneWidget);
    // The Jupiter–Saturn double transit card is present and active.
    expect(find.text('Double Transit'), findsOneWidget);
    expect(find.text('GURU–SHANI GOCHAR'), findsOneWidget);
    expect(find.text('ACTIVATED HOUSES'), findsOneWidget);
    // The badge legend explains the row badges present in the current sky.
    expect(find.text('KEY'), findsOneWidget);
    expect(find.text('Retrograde'), findsOneWidget);
    expect(find.text('Own sign'), findsOneWidget);
  });

  testWidgets('toggling the reference frame switches to Lagna houses',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final controller = _mockController(<String?>[]);
    addTearDown(controller.dispose);

    await _pump(tester, birthInputState: birthInputState, controller: controller);

    await tester.tap(find.text('From Lagna'));
    await tester.pumpAndSettle();

    expect(find.text('House from Lagna'), findsOneWidget);
    expect(find.text('House from Moon'), findsNothing);
  });

  testWidgets('opens a planet detail sheet when a row is tapped',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final controller = _mockController(<String?>[]);
    addTearDown(controller.dispose);

    await _pump(tester, birthInputState: birthInputState, controller: controller);

    await tester.tap(find.text('Guru'));
    await tester.pumpAndSettle();

    expect(find.text('HOUSE ACTIVATED'), findsOneWidget);
    expect(find.text('MOVEMENT'), findsOneWidget);
    expect(find.text('TRANSIT STRENGTH (ASHTAKAVARGA)'), findsOneWidget);
  });

  testWidgets('tapping a highlight chip opens that planet detail',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final controller = _mockController(<String?>[]);
    addTearDown(controller.dispose);

    await _pump(tester, birthInputState: birthInputState, controller: controller);

    // The "Guru exalted" highlight chip should open Jupiter's detail sheet.
    await tester.tap(find.text('Guru exalted'));
    await tester.pumpAndSettle();

    expect(find.text('HOUSE ACTIVATED'), findsOneWidget);
  });

  testWidgets('asks for birth details when none are set',
      (WidgetTester tester) async {
    final birthInputState = BirthInputState(
      firstName: 'Sahil',
      dateOfBirth: '',
      timeOfBirth: '',
      placeOfBirth: '',
    );
    addTearDown(birthInputState.dispose);

    await _pump(tester, birthInputState: birthInputState);

    expect(find.text('Birth details needed'), findsOneWidget);
    expect(find.text('Planet Transits'), findsNothing);
  });
}
