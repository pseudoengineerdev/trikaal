import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trikaal_mobile/main.dart';

void main() {
  testWidgets('App starts onboarding flow', (WidgetTester tester) async {
    // No persisted session: a fresh install must land on onboarding.
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const TrikaalApp());
    // Let the local session restore resolve (it finds nothing) so the shell
    // moves past its loading gate into onboarding.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Let\'s start with your first name'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
