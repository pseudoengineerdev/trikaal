import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/state/terminology_mode_state.dart';
import 'package:trikaal_mobile/features/home/presentation/widgets/home_header_tabs.dart';

Widget _appWithTabs({
  required HomeTab activeTab,
  required ValueChanged<HomeTab> onTabSelected,
  required TerminologyModeState terminologyModeState,
}) {
  return MaterialApp(
    home: Scaffold(
      appBar: HomeHeaderTabs(
        activeTab: activeTab,
        onTabSelected: onTabSelected,
        terminologyListenable: terminologyModeState,
        onTerminologyChanged: terminologyModeState.setMode,
      ),
      body: const SizedBox.shrink(),
    ),
  );
}

void main() {
  group('HomeHeaderTabs', () {
    testWidgets('renders Today/Feed tabs around the Sanskrit/English toggle',
        (WidgetTester tester) async {
      final terminology = TerminologyModeState();
      addTearDown(terminology.dispose);

      await tester.pumpWidget(
        _appWithTabs(
          activeTab: HomeTab.today,
          onTabSelected: (_) {},
          terminologyModeState: terminology,
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Sanskrit'), findsOneWidget);
      expect(find.text('ॐ'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      // The sparkle icon was replaced by the Om glyph.
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    });

    testWidgets('tapping a tab reports the selection',
        (WidgetTester tester) async {
      final terminology = TerminologyModeState();
      addTearDown(terminology.dispose);
      final selections = <HomeTab>[];

      await tester.pumpWidget(
        _appWithTabs(
          activeTab: HomeTab.today,
          onTabSelected: selections.add,
          terminologyModeState: terminology,
        ),
      );

      await tester.tap(find.text('Feed'));
      expect(selections, <HomeTab>[HomeTab.feed]);

      await tester.tap(find.text('Today'));
      expect(selections, <HomeTab>[HomeTab.feed, HomeTab.today]);
    });

    testWidgets('toggle switches terminology mode',
        (WidgetTester tester) async {
      final terminology = TerminologyModeState();
      addTearDown(terminology.dispose);

      await tester.pumpWidget(
        _appWithTabs(
          activeTab: HomeTab.today,
          onTabSelected: (_) {},
          terminologyModeState: terminology,
        ),
      );

      await tester.tap(find.text('English'));
      expect(terminology.mode, TerminologyMode.english);

      await tester.tap(find.text('Sanskrit'));
      expect(terminology.mode, TerminologyMode.vedic);
    });
  });
}
