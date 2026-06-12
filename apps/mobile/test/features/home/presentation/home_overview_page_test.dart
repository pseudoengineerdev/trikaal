import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/features/feed/presentation/feed_page.dart';
import 'package:trikaal_mobile/features/home/presentation/home_overview_page.dart';

const String _todayEmptyStateText =
    'We need your birth mix to build your personalized home.';

/// Advances through the tab transition (280ms) and the dummy feed's
/// simulated load latency (400ms). Bounded pumps because the feed footer
/// spinner never settles.
Future<void> _pumpThroughTransition(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BirthInputState> pumpHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final state = BirthInputState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(home: HomeOverviewPage(birthInputState: state)),
    );
    await tester.pump();
    return state;
  }

  group('HomeOverviewPage tabs', () {
    testWidgets('starts on Today with the Feed tab collapsed',
        (WidgetTester tester) async {
      await pumpHome(tester);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text(_todayEmptyStateText), findsOneWidget);
      expect(find.byType(FeedView), findsNothing);
    });

    testWidgets('tab taps animate between Today and Feed',
        (WidgetTester tester) async {
      await pumpHome(tester);

      await tester.tap(find.text('Feed'));
      await _pumpThroughTransition(tester);

      expect(find.byType(FeedView), findsOneWidget);
      expect(find.text(_todayEmptyStateText), findsNothing);

      await tester.tap(find.text('Today'));
      await _pumpThroughTransition(tester);

      expect(find.text(_todayEmptyStateText), findsOneWidget);
    });

    testWidgets('horizontal swipe also switches tabs',
        (WidgetTester tester) async {
      await pumpHome(tester);

      await tester.fling(
        find.text(_todayEmptyStateText),
        const Offset(-300, 0),
        1200,
      );
      await _pumpThroughTransition(tester);

      expect(find.byType(FeedView), findsOneWidget);
      expect(find.text(_todayEmptyStateText), findsNothing);
    });
  });
}
