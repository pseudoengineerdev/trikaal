import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_report_models.dart';
import 'package:trikaal_mobile/features/home/presentation/widgets/today_view.dart';

import '../../../../helpers/sample_report.dart';

BirthInputState _stateWithReport() {
  final birthInputState = BirthInputState(
    firstName: 'Sahil',
    dateOfBirth: '1999-07-04',
    timeOfBirth: '12:22',
    placeOfBirth: 'Mumbai',
  );
  birthInputState.markReportComputed(
    ComputeReportResponse.fromJson(sampleReportJson()),
  );
  return birthInputState;
}

Future<void> _pumpTodayView(WidgetTester tester, BirthInputState state) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TodayView(
          birthInputState: state,
          now: DateTime(2026, 6, 12),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('TodayView', () {
    testWidgets('shows the date hero, greeting, and scope pills',
        (WidgetTester tester) async {
      final state = _stateWithReport();
      addTearDown(state.dispose);

      await _pumpTodayView(tester, state);

      expect(find.text('Namaste, Sahil'), findsOneWidget);
      expect(find.text('June 12'), findsOneWidget);
      expect(find.text('Friday'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('renders the reading and all six level cards',
        (WidgetTester tester) async {
      final state = _stateWithReport();
      addTearDown(state.dispose);

      await _pumpTodayView(tester, state);

      expect(find.text('Your reading for today'), findsOneWidget);
      expect(find.text("Today's levels"), findsOneWidget);
      expect(find.text('Fortune'), findsOneWidget);
      expect(find.text('Love'), findsOneWidget);
      expect(find.text('Career'), findsOneWidget);
      expect(find.text('Intuition'), findsOneWidget);
      expect(find.text('Vitality'), findsOneWidget);
      expect(find.text('Wealth'), findsOneWidget);
      expect(find.text('Guru · 9th bhava'), findsOneWidget);
      expect(find.text('Chandra · Tarabala'), findsOneWidget);
    });

    testWidgets('never displays fabricated percentages',
        (WidgetTester tester) async {
      final state = _stateWithReport();
      addTearDown(state.dispose);

      await _pumpTodayView(tester, state);

      expect(find.textContaining('%'), findsNothing);
      expect(
        find.text('Preview levels — your precise Vedic engine is on its way.'),
        findsOneWidget,
      );
    });

    testWidgets('switching scope swaps the reading and levels sections',
        (WidgetTester tester) async {
      final state = _stateWithReport();
      addTearDown(state.dispose);

      await _pumpTodayView(tester, state);

      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();
      expect(find.text('Your reading for tomorrow'), findsOneWidget);
      expect(find.text("Tomorrow's levels"), findsOneWidget);
      expect(find.text('Your reading for today'), findsNothing);

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.text('Your reading for this month'), findsOneWidget);
      expect(find.text("This month's levels"), findsOneWidget);
      // The date hero stays anchored to today.
      expect(find.text('June 12'), findsOneWidget);
    });

    testWidgets('does not render the sign trio section',
        (WidgetTester tester) async {
      final state = _stateWithReport();
      addTearDown(state.dispose);

      await _pumpTodayView(tester, state);

      expect(find.text('Your Sign Trio'), findsNothing);
    });
  });
}
