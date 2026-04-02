import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/home/presentation/astrology/rashi_insights.dart';

void main() {
  test('rashiInsightFor returns Aries mapping for Mesh', () {
    final insight = rashiInsightFor('Mesh');

    expect(insight.name, 'Aries');
    expect(insight.symbol, '♈');
    expect(insight.element, 'Fire');
  });

  test('rashiInsightFor resolves aliases', () {
    final insight = rashiInsightFor('Maka');

    expect(insight.name, 'Capricorn');
    expect(insight.symbol, '♑');
  });

  test('rashiInsightFor falls back for unknown code', () {
    final insight = rashiInsightFor('??');

    expect(insight.name, 'Unknown');
    expect(insight.symbol, '✦');
  });
}
