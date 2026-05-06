import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/app/theme/trikaal_theme.dart';
import 'package:trikaal_mobile/features/features/presentation/birth_chart_detail_page.dart';
import 'package:trikaal_mobile/features/features/presentation/features_grid_page.dart';
import 'package:trikaal_mobile/features/kaal_sarpa/presentation/kaal_sarpa_page.dart';

void main() {
  testWidgets('shows simple 2-column feature cards without removed sections',
      (WidgetTester tester) async {
    final birthInputState = BirthInputState(
      firstName: 'Sahil',
      dateOfBirth: '1999-07-04',
      timeOfBirth: '12:22',
      placeOfBirth: 'Mumbai',
    );
    addTearDown(birthInputState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: TrikaalTheme.dark(),
        home: FeaturesGridPage(birthInputState: birthInputState),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Birth Chart'), findsOneWidget);
    expect(find.text('Your Soulmate'), findsOneWidget);
    expect(find.text('Pancha Pakshi'), findsOneWidget);
    expect(find.text('Mangal Dosh'), findsOneWidget);
    expect(find.text('Kaal Sarpa Dosh'), findsOneWidget);
    expect(find.text('🪐'), findsNothing);
    expect(find.text('💞'), findsNothing);
    expect(find.textContaining('🕊'), findsNothing);
    expect(find.text('🔥'), findsNothing);

    expect(find.text('Tarot Readings'), findsNothing);
    expect(find.text('Meditation'), findsNothing);
    expect(find.text('Compatibility'), findsNothing);
    expect(find.text('Rising Sign'), findsNothing);
    expect(find.textContaining('☉'), findsNothing);
    expect(find.textContaining('☽'), findsNothing);
    expect(find.textContaining('↑'), findsNothing);
  });

  testWidgets('opens birth chart details from the primary module card',
      (WidgetTester tester) async {
    final birthInputState = BirthInputState(
      firstName: 'Sahil',
      dateOfBirth: '1999-07-04',
      timeOfBirth: '12:22',
      placeOfBirth: 'Mumbai',
    );
    addTearDown(birthInputState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: TrikaalTheme.dark(),
        home: FeaturesGridPage(birthInputState: birthInputState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Birth Chart'));
    await tester.pumpAndSettle();

    expect(find.byType(BirthChartDetailPage), findsOneWidget);
  });

  testWidgets('opens Kaal Sarpa page from the Kaal Sarpa feature card',
      (WidgetTester tester) async {
    final birthInputState = BirthInputState(
      firstName: 'Sahil',
      dateOfBirth: '',
      timeOfBirth: '',
      placeOfBirth: '',
    );
    addTearDown(birthInputState.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: TrikaalTheme.dark(),
        home: FeaturesGridPage(birthInputState: birthInputState),
      ),
    );
    await tester.pumpAndSettle();

    final kaalSarpaCardFinder = find.text('Kaal Sarpa Dosh').first;
    await tester.ensureVisible(kaalSarpaCardFinder);
    await tester.tap(kaalSarpaCardFinder, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(KaalSarpaPage), findsOneWidget);
    expect(find.text('Kaal Sarpa Dosh'), findsAtLeastNWidgets(1));
  });
}
