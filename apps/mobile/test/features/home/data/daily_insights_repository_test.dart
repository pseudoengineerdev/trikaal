import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/home/data/daily_insights_repository.dart';
import 'package:trikaal_mobile/features/home/domain/daily_insights.dart';
import 'package:trikaal_mobile/features/home/presentation/astrology/rashi_insights.dart';
import 'package:trikaal_mobile/features/shared/astrology/sign_trio_insights.dart';

SignTrioInsights _trio() {
  return SignTrioInsights(
    sun: rashiInsightFor('Mitu'),
    moon: rashiInsightFor('Kumb'),
    rising: rashiInsightFor('Kany'),
  );
}

void main() {
  group('PlaceholderDailyInsightsRepository', () {
    const repository = PlaceholderDailyInsightsRepository();
    final anchor = DateTime(2026, 6, 12);

    test('returns a reading with six metrics for every scope', () async {
      for (final scope in ReadingScope.values) {
        final reading = await repository.fetchReading(
          scope: scope,
          anchor: anchor,
          trio: _trio(),
        );

        expect(reading.scope, scope);
        expect(reading.text, isNotEmpty);
        expect(reading.metrics, hasLength(6));
        for (final metric in reading.metrics) {
          expect(metric.strength, inInclusiveRange(0.0, 1.0));
          expect(metric.tierLabel, isNotEmpty);
          expect(metric.basis, isNotEmpty);
          expect(metric.glyph, isNotEmpty);
        }
      }
    });

    test('is deterministic for the same date, scope, and natal trio',
        () async {
      final first = await repository.fetchReading(
        scope: ReadingScope.today,
        anchor: anchor,
        trio: _trio(),
      );
      final second = await repository.fetchReading(
        scope: ReadingScope.today,
        anchor: anchor,
        trio: _trio(),
      );

      expect(first.text, second.text);
      for (var i = 0; i < first.metrics.length; i++) {
        expect(first.metrics[i].tierLabel, second.metrics[i].tierLabel);
        expect(first.metrics[i].strength, second.metrics[i].strength);
      }
    });

    test('reading is grounded in the natal trio, not invented transits',
        () async {
      final reading = await repository.fetchReading(
        scope: ReadingScope.today,
        anchor: anchor,
        trio: _trio(),
      );

      expect(reading.text, contains('Moon in Aquarius'));
      expect(reading.text, contains('Virgo'));
    });

    test('scopes produce distinct readings on the same day', () async {
      final today = await repository.fetchReading(
        scope: ReadingScope.today,
        anchor: anchor,
        trio: _trio(),
      );
      final monthly = await repository.fetchReading(
        scope: ReadingScope.monthly,
        anchor: anchor,
        trio: _trio(),
      );

      expect(today.text, isNot(monthly.text));
    });

    test('metric set covers the six Vedic bases', () async {
      final reading = await repository.fetchReading(
        scope: ReadingScope.today,
        anchor: anchor,
        trio: _trio(),
      );

      final keys = reading.metrics.map((DailyMetric m) => m.key).toList();
      expect(
        keys,
        <String>['bhagya', 'love', 'career', 'mind', 'vitality', 'gains'],
      );
      final bases = reading.metrics.map((DailyMetric m) => m.basis).join(' ');
      expect(bases, contains('9th bhava'));
      expect(bases, contains('Tarabala'));
      expect(bases, contains('Lagna'));
    });
  });
}
