import 'package:flutter_test/flutter_test.dart';

import 'package:trikaal_mobile/main.dart';

void main() {
  testWidgets('App renders birth chart screen title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TrikaalApp());

    expect(find.text('Trikaal Birth Chart'), findsOneWidget);
  });
}
