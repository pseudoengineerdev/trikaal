import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trikaal_mobile/app/widgets/trikaal_app_bar.dart';
import 'package:trikaal_mobile/features/feed/presentation/feed_page.dart';

Widget _appWithBar({String? rightCtaLabel}) {
  return MaterialApp(
    home: Builder(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: rightCtaLabel == null
              ? buildTrikaalAppBar(context)
              : buildTrikaalAppBar(context, rightCtaLabel: rightCtaLabel),
          body: const SizedBox.shrink(),
        );
      },
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildTrikaalAppBar right CTA', () {
    testWidgets('defaults to Feed and opens the feed page',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(_appWithBar());

      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Actions'), findsNothing);

      await tester.tap(find.text('Feed'));
      // Bounded pumps: the feed's footer spinner never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(FeedPage), findsOneWidget);
    });

    testWidgets('label-only overrides keep the placeholder behavior',
        (WidgetTester tester) async {
      await tester.pumpWidget(_appWithBar(rightCtaLabel: 'Insights'));

      await tester.tap(find.text('Insights'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FeedPage), findsNothing);
      expect(
        find.text('More quick actions are coming soon.'),
        findsOneWidget,
      );
    });
  });
}
