import 'package:flutter_test/flutter_test.dart';

import 'package:trikaal_mobile/main.dart';

void main() {
  testWidgets('App starts onboarding flow', (WidgetTester tester) async {
    await tester.pumpWidget(const TrikaalApp());

    expect(find.text('Let\'s start with your first name'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
