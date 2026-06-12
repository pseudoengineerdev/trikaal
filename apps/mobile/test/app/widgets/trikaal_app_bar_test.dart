import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/widgets/trikaal_app_bar.dart';

Widget _appWithBar({
  VoidCallback? onCurrentLocationTap,
  VoidCallback? onCalendarTap,
  VoidCallback? onPremiumTap,
}) {
  return MaterialApp(
    home: Builder(
      builder: (BuildContext context) {
        return Scaffold(
          appBar: buildTrikaalAppBar(
            context,
            onCurrentLocationTap: onCurrentLocationTap,
            onCalendarTap: onCalendarTap,
            onPremiumTap: onPremiumTap,
          ),
          body: const SizedBox.shrink(),
        );
      },
    ),
  );
}

void main() {
  group('buildTrikaalAppBar', () {
    testWidgets(
        'shows notifications + location on the left and calendar + premium '
        'on the right', (WidgetTester tester) async {
      var locationTaps = 0;
      var calendarTaps = 0;
      var premiumTaps = 0;

      await tester.pumpWidget(
        _appWithBar(
          onCurrentLocationTap: () => locationTaps++,
          onCalendarTap: () => calendarTaps++,
          onPremiumTap: () => premiumTaps++,
        ),
      );

      expect(find.text('Trikaal'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.location_on_rounded));
      await tester.tap(find.byIcon(Icons.calendar_month_rounded));
      await tester.tap(find.byIcon(Icons.auto_awesome_rounded));

      expect(locationTaps, 1);
      expect(calendarTaps, 1);
      expect(premiumTaps, 1);
    });

    testWidgets('hides optional icons and renders no second row by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(_appWithBar());

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsNothing);
      expect(find.byIcon(Icons.calendar_month_rounded), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
      expect(find.text('Today'), findsNothing);
      expect(find.text('Feed'), findsNothing);
    });

    testWidgets('notification tap falls back to the coming-soon snackbar',
        (WidgetTester tester) async {
      await tester.pumpWidget(_appWithBar());

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pump();

      expect(
        find.text(
          'Notifications and home-screen widget controls are coming soon.',
        ),
        findsOneWidget,
      );
    });
  });
}
