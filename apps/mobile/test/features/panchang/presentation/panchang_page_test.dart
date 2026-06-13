import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/app/theme/trikaal_theme.dart';
import 'package:trikaal_mobile/features/charts/data/chart_api_client.dart';
import 'package:trikaal_mobile/features/panchang/presentation/panchang_page.dart';
import 'package:trikaal_mobile/features/panchang/presentation/state/panchang_controller.dart';
import 'package:trikaal_mobile/features/panchang/presentation/state/panchang_time_format_state.dart';

import '../../../helpers/sample_panchang.dart';

BirthInputState _birthInputState() {
  return BirthInputState(
    firstName: 'Sahil',
    dateOfBirth: '1999-07-04',
    timeOfBirth: '12:22',
    placeOfBirth: 'Vadodara',
  );
}

/// Fixed clock so "today" — and therefore the requested date and every
/// rendered time string — is deterministic regardless of when the suite runs.
DateTime _fixedNow() => DateTime(2026, 6, 12, 9, 0);

PanchangController _controllerWithMockApi(
  List<String> requestedDates, {
  bool withAbhijit = true,
  bool withPanchaka = false,
  bool withBhadra = false,
}) {
  final mockClient = MockClient((http.Request request) async {
    final payload = jsonDecode(request.body) as Map<String, dynamic>;
    final date = payload['date'] as String;
    requestedDates.add(date);
    return http.Response(
      jsonEncode(
        samplePanchangResponseJson(
          date,
          withAbhijit: withAbhijit,
          withPanchaka: withPanchaka,
          withBhadra: withBhadra,
        ),
      ),
      200,
      headers: <String, String>{'Content-Type': 'application/json'},
    );
  });
  return PanchangController(
    apiClient: ChartApiClient(
      baseUrl: 'http://localhost:1',
      httpClient: mockClient,
    ),
  );
}

Future<void> _pumpPanchangPage(
  WidgetTester tester, {
  required BirthInputState birthInputState,
  required PanchangController controller,
  DateTime Function()? now,
}) async {
  // Tall surface so every section card is laid out without scrolling.
  tester.view.physicalSize = const Size(1080, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: TrikaalTheme.dark(),
      home: PanchangPage(
        birthInputState: birthInputState,
        controller: controller,
        now: now ?? _fixedNow,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PanchangTimeFormatState.shared.setFormat(PanchangTimeFormat.h12);
  });

  testWidgets('renders the full daily panchang sections',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final requestedDates = <String>[];
    final controller = _controllerWithMockApi(requestedDates);
    addTearDown(controller.dispose);

    await _pumpPanchangPage(
      tester,
      birthInputState: birthInputState,
      controller: controller,
    );

    expect(find.text('Dainik Panchang'), findsOneWidget);
    expect(find.text('Krishna Dvadashi'), findsWidgets);
    expect(find.text('Shukravara'), findsWidgets);
    expect(find.text('Panchangam'), findsOneWidget);
    // Grouped limb sections with left-aligned names and pinned time cells.
    expect(find.text('TITHI'), findsOneWidget);
    expect(find.text('NAKSHATRA'), findsOneWidget);
    expect(find.text('YOGA'), findsOneWidget);
    expect(find.text('KARANA'), findsOneWidget);
    expect(find.text('VARA'), findsOneWidget);
    expect(find.text('upto 07:37 PM'), findsWidgets);
    expect(find.text('Shubha Muhurat'), findsOneWidget);
    expect(find.text('Ashubha Muhurat'), findsOneWidget);
    expect(find.text('Rahu Kalam'), findsOneWidget);
    expect(find.text('10:56 AM – 12:37 PM'), findsOneWidget);
    expect(find.text('Vikram Samvat'), findsOneWidget);
    expect(find.text('2083 · Siddharthi'), findsOneWidget);
    expect(find.text('Hora Timeline'), findsOneWidget);
    expect(find.text('Choghadiya'), findsOneWidget);
    // Ganda Moola folds the nakshatra into the label and keeps a warn glyph.
    expect(find.text('Ganda Moola · Ashwini'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
    // Next-day moonrise: clock on one line, date demoted to a sub-line.
    expect(find.text('03:44 AM'), findsOneWidget);
    expect(find.text('Jun 13'), findsWidgets);
    expect(requestedDates.length, 1);
  });

  testWidgets('defaults to 12-hour times and switches to 24+ on toggle',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final controller = _controllerWithMockApi(<String>[]);
    addTearDown(controller.dispose);

    await _pumpPanchangPage(
      tester,
      birthInputState: birthInputState,
      controller: controller,
    );

    // Amrit Kalam crosses midnight: the span stays on one line and the
    // date moves to a small sub-line.
    expect(find.text('11:47 PM – 01:13 AM'), findsOneWidget);
    expect(find.text('ends Jun 13'), findsOneWidget);

    await tester.tap(find.text('24 Hrs+'));
    await tester.pumpAndSettle();

    // The same window now rolls past 24 with no date sub-line.
    expect(find.text('23:47 – 25:13'), findsOneWidget);
    expect(find.text('11:47 PM – 01:13 AM'), findsNothing);
    expect(find.text('ends Jun 13'), findsNothing);
  });

  testWidgets('swiping to the previous day requests the previous date',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final requestedDates = <String>[];
    final controller = _controllerWithMockApi(requestedDates);
    addTearDown(controller.dispose);

    await _pumpPanchangPage(
      tester,
      birthInputState: birthInputState,
      controller: controller,
    );
    expect(requestedDates.length, 1);
    final today = DateTime.parse(requestedDates.first);

    await tester.fling(
      find.byType(PageView),
      const Offset(420, 0),
      900,
    );
    await tester.pumpAndSettle();

    expect(requestedDates.length, 2);
    final previous = DateTime.parse(requestedDates.last);
    expect(today.difference(previous).inDays, 1);
  });

  testWidgets('tapping next-day chevron requests the next date',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final requestedDates = <String>[];
    final controller = _controllerWithMockApi(requestedDates);
    addTearDown(controller.dispose);

    await _pumpPanchangPage(
      tester,
      birthInputState: birthInputState,
      controller: controller,
    );

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();

    expect(requestedDates.length, 2);
    final today = DateTime.parse(requestedDates.first);
    final next = DateTime.parse(requestedDates.last);
    expect(next.difference(today).inDays, 1);
    expect(find.text('Back to today'), findsOneWidget);
  });

  testWidgets('shows the muted Abhijit note when the window is absent',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final controller =
        _controllerWithMockApi(<String>[], withAbhijit: false);
    addTearDown(controller.dispose);

    await _pumpPanchangPage(
      tester,
      birthInputState: birthInputState,
      controller: controller,
    );

    expect(find.text('Abhijit Muhurta'), findsOneWidget);
    expect(find.text('Not observed'), findsOneWidget);
    expect(find.text('on Budhavara'), findsOneWidget);
  });

  testWidgets('renders Panchaka and Bhadra (Vishti) rows when present',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final controller = _controllerWithMockApi(
      <String>[],
      withPanchaka: true,
      withBhadra: true,
    );
    addTearDown(controller.dispose);

    await _pumpPanchangPage(
      tester,
      birthInputState: birthInputState,
      controller: controller,
    );

    expect(find.text('Mrityu Panchaka'), findsOneWidget);
    expect(find.text('Bhadra (Vishti)'), findsOneWidget);
    // The Vishti karana also surfaces in the five-limbs Karana group.
    expect(find.text('Vishti'), findsWidgets);
  });

  testWidgets('marks the live window with a NOW pill at a fixed clock',
      (WidgetTester tester) async {
    final birthInputState = _birthInputState();
    addTearDown(birthInputState.dispose);
    final controller = _controllerWithMockApi(<String>[]);
    addTearDown(controller.dispose);

    await _pumpPanchangPage(
      tester,
      birthInputState: birthInputState,
      controller: controller,
      // 09:00 falls inside Gulikai Kalam (07:36–09:16).
      now: () => DateTime(2026, 6, 12, 9, 0),
    );

    expect(find.text('NOW'), findsWidgets);
  });
}
