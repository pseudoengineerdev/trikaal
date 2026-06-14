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
import 'package:trikaal_mobile/features/hora/presentation/hora_page.dart';
import 'package:trikaal_mobile/features/hora/presentation/state/hora_controller.dart';
import 'package:trikaal_mobile/features/panchang/presentation/state/panchang_time_format_state.dart';

import '../../../helpers/sample_hora.dart';

// 09:00 IST on the Vadodara Friday, expressed as a UTC instant so the live
// current-hora detection is deterministic regardless of the test host's clock.
DateTime _fixedNow() => DateTime.utc(2026, 6, 12, 3, 30);

BirthInputState _birthInputState({String place = 'Vadodara'}) {
  return BirthInputState(
    firstName: 'Sahil',
    dateOfBirth: '1999-07-04',
    timeOfBirth: '12:22',
    placeOfBirth: place,
  );
}

HoraController _mockController(List<String> requestedDates) {
  final mockClient = MockClient((http.Request request) async {
    final payload = jsonDecode(request.body) as Map<String, dynamic>;
    final date = payload['date'] as String;
    requestedDates.add(date);
    return http.Response(
      jsonEncode(sampleHoraResponseJson(date)),
      200,
      headers: <String, String>{'Content-Type': 'application/json'},
    );
  });
  return HoraController(
    apiClient:
        ChartApiClient(baseUrl: 'http://localhost:1', httpClient: mockClient),
    now: _fixedNow,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required BirthInputState birthInputState,
  HoraController? controller,
}) async {
  tester.view.physicalSize = const Size(1080, 9000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TrikaalTheme.dark(),
      home: HoraPage(
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
    // Even with the app-wide format on 24h+, Hora must render a 12-hour clock.
    PanchangTimeFormatState.shared.setFormat(PanchangTimeFormat.h24plus);
    TerminologyModeState.shared.setMode(TerminologyMode.vedic);
  });

  testWidgets('renders the live current hora and the day/night timelines',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final requestedDates = <String>[];
    final controller = _mockController(requestedDates);
    addTearDown(controller.dispose);

    await _pump(tester,
        birthInputState: birthInputState, controller: controller);

    expect(requestedDates, contains('2026-06-12'));
    expect(find.text('Planetary Hours'), findsOneWidget);
    expect(find.text('CURRENT HORA'), findsOneWidget);
    // 09:00 -> the Moon (Chandra) hora is live.
    expect(find.text('Chandra hora'), findsOneWidget);
    expect(find.text('Day horas'), findsOneWidget);
    expect(find.text('Night horas'), findsOneWidget);
    // Exactly one slot is marked live.
    expect(find.text('NOW'), findsOneWidget);
    expect(find.text('FAVOURABLE FOR'), findsWidgets);

    // 12-hour clock is forced (no 24h+ roll past midnight), and night horas
    // after midnight carry a compact "(+1)" next-day marker.
    expect(find.textContaining('AM'), findsWidgets);
    expect(find.textContaining('30:00'), findsNothing);
    expect(find.textContaining('(+1)'), findsWidgets);

    // Unmount the page, then stop the controller's live ticker before the
    // binding's pending-timer check runs.
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('opens a hora detail sheet when a timeline row is tapped',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final controller = _mockController(<String>[]);
    addTearDown(controller.dispose);

    await _pump(tester,
        birthInputState: birthInputState, controller: controller);

    // Tap the first day hora row (Shukra / Venus on a Friday).
    await tester.tap(find.text('Shukra').first);
    await tester.pumpAndSettle();

    expect(find.text('Shukra hora'), findsOneWidget);
    expect(find.text('BEST TO AVOID'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('asks for a location when none is set',
      (WidgetTester tester) async {
    final birthInputState = BirthInputState(
      firstName: 'Sahil',
      dateOfBirth: '',
      timeOfBirth: '',
      placeOfBirth: '',
    );
    addTearDown(birthInputState.dispose);

    await _pump(tester, birthInputState: birthInputState);

    expect(find.text('Location needed'), findsOneWidget);
    expect(find.text('Planetary Hours'), findsNothing);
  });
}
