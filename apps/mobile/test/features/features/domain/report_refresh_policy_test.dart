import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/features/domain/report_refresh_policy.dart';

void main() {
  group('shouldAutoRefreshReportForDay', () {
    test('returns false when report is for same local day', () {
      final now = DateTime(2026, 4, 3, 10, 30);
      final asOfIso = DateTime(2026, 4, 3, 1, 15).toIso8601String();

      final shouldRefresh = shouldAutoRefreshReportForDay(
        asOfIso,
        now: now,
      );

      expect(shouldRefresh, isFalse);
    });

    test('returns true when report is from previous day', () {
      final now = DateTime(2026, 4, 3, 10, 30);
      final asOfIso = DateTime(2026, 4, 2, 23, 59).toIso8601String();

      final shouldRefresh = shouldAutoRefreshReportForDay(
        asOfIso,
        now: now,
      );

      expect(shouldRefresh, isTrue);
    });

    test('returns false for invalid asOf timestamp', () {
      final now = DateTime(2026, 4, 3, 10, 30);

      final shouldRefresh = shouldAutoRefreshReportForDay(
        'not-a-date',
        now: now,
      );

      expect(shouldRefresh, isFalse);
    });
  });

  group('formatReportAsOfForDisplay', () {
    test('formats valid timestamp to compact local display', () {
      final asOfIso = DateTime(2026, 4, 3, 9, 5).toIso8601String();
      final formatted = formatReportAsOfForDisplay(asOfIso);

      expect(formatted, equals('2026-04-03 09:05'));
    });

    test('returns placeholder for invalid timestamp', () {
      final formatted = formatReportAsOfForDisplay('bad-value');

      expect(formatted, equals('—'));
    });
  });

  group('formatActiveWindowForDisplay', () {
    test('formats active window into human-readable range', () {
      final start = DateTime(2025, 12, 28, 1, 48).toIso8601String();
      final end = DateTime(2027, 7, 29, 9, 1).toIso8601String();

      final formatted = formatActiveWindowForDisplay(start, end);

      expect(
        formatted,
        equals('Dec 28, 2025 1:48 AM → Jul 29, 2027 9:01 AM'),
      );
    });

    test('falls back to raw values when parsing fails', () {
      final formatted = formatActiveWindowForDisplay('bad-start', 'bad-end');

      expect(formatted, equals('bad-start → bad-end'));
    });
  });
}
