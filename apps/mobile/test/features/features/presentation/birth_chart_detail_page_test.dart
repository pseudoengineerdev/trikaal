import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/state/birth_input_state.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_report_models.dart';
import 'package:trikaal_mobile/features/features/presentation/birth_chart_detail_page.dart';

import '../../../helpers/sample_report.dart';

void main() {
  testWidgets('table tab defaults to D1 and keeps ascendant row first',
      (WidgetTester tester) async {
    final birthInputState = BirthInputState(
      firstName: 'Sahil',
      dateOfBirth: '1999-07-04',
      timeOfBirth: '12:22',
      placeOfBirth: 'Mumbai',
    );
    addTearDown(birthInputState.dispose);
    birthInputState.markReportComputed(
      ComputeReportResponse.fromJson(sampleReportJson()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BirthChartDetailPage(birthInputState: birthInputState),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('table-chart-selector')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('table-D1-degree-sun')),
        findsOneWidget);
    expect(find.byKey(const ValueKey<String>('table-D1-graha-lagna')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey<String>('table-chart-status')), findsNothing);
    expect(
        find.byKey(const ValueKey<String>('table-chart-source')), findsNothing);

    final lagnaPosition = tester
        .getTopLeft(find.byKey(const ValueKey<String>('table-D1-graha-lagna')));
    final sunPosition = tester
        .getTopLeft(find.byKey(const ValueKey<String>('table-D1-graha-sun')));
    expect(lagnaPosition.dy, lessThan(sunPosition.dy));

    await tester
        .tap(find.byKey(const ValueKey<String>('table-chart-selector')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('table-chart-option-D9')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    final d9Degree = tester.widget<Text>(
      find.byKey(const ValueKey<String>('table-D9-degree-sun')),
    );
    expect(d9Degree.data, '18°01\'12"');
    final d9LagnaPosition = tester
        .getTopLeft(find.byKey(const ValueKey<String>('table-D9-graha-lagna')));
    final d9SunPosition = tester
        .getTopLeft(find.byKey(const ValueKey<String>('table-D9-graha-sun')));
    expect(d9LagnaPosition.dy, lessThan(d9SunPosition.dy));
    expect(find.byKey(const ValueKey<String>('table-D9-house-sun')),
        findsOneWidget);

    expect(find.byType(DataTable), findsOneWidget);
  });
}
