import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/panchang/data/models/panchang_models.dart';
import 'package:trikaal_mobile/features/panchang/domain/panchang_time_formatter.dart';
import 'package:trikaal_mobile/features/panchang/presentation/state/panchang_time_format_state.dart';

PanchangTimeBundle _bundle(String localIso) {
  return PanchangTimeBundle(
    utcIso: localIso,
    localIso: localIso,
    localTime: localIso.substring(11, 16),
  );
}

void main() {
  const date = '2026-06-12';

  group('formatPanchangMoment', () {
    test('renders a same-day moment in 12-hour form', () {
      final formatted = formatPanchangMoment(
        _bundle('2026-06-12T19:37:25+05:30'),
        panchangDateIso: date,
        format: PanchangTimeFormat.h12,
      );
      expect(formatted, '07:37 PM');
    });

    test('appends the date for a next-day moment in 12-hour form', () {
      final formatted = formatPanchangMoment(
        _bundle('2026-06-13T04:06:12+05:30'),
        panchangDateIso: date,
        format: PanchangTimeFormat.h12,
      );
      expect(formatted, '04:06 AM, Jun 13');
    });

    test('renders midnight and noon correctly in 12-hour form', () {
      expect(
        formatPanchangMoment(
          _bundle('2026-06-12T00:15:00+05:30'),
          panchangDateIso: date,
          format: PanchangTimeFormat.h12,
        ),
        '12:15 AM',
      );
      expect(
        formatPanchangMoment(
          _bundle('2026-06-12T12:10:00+05:30'),
          panchangDateIso: date,
          format: PanchangTimeFormat.h12,
        ),
        '12:10 PM',
      );
    });

    test('rolls next-day moments past 24 in 24+ form', () {
      final formatted = formatPanchangMoment(
        _bundle('2026-06-13T01:13:00+05:30'),
        panchangDateIso: date,
        format: PanchangTimeFormat.h24plus,
      );
      expect(formatted, '25:13');
    });

    test('keeps same-day moments plain in 24+ form', () {
      final formatted = formatPanchangMoment(
        _bundle('2026-06-12T19:37:00+05:30'),
        panchangDateIso: date,
        format: PanchangTimeFormat.h24plus,
      );
      expect(formatted, '19:37');
    });

    test('falls back to dated 12-hour form for moments before the date', () {
      final formatted = formatPanchangMoment(
        _bundle('2026-06-11T22:36:00+05:30'),
        panchangDateIso: date,
        format: PanchangTimeFormat.h24plus,
      );
      expect(formatted, '10:36 PM, Jun 11');
    });
  });

  group('formatPanchangRange', () {
    test('joins both ends with an en dash', () {
      final window = PanchangWindow(
        start: _bundle('2026-06-12T10:56:00+05:30'),
        end: _bundle('2026-06-12T12:37:00+05:30'),
      );
      expect(
        formatPanchangRange(
          window,
          panchangDateIso: date,
          format: PanchangTimeFormat.h12,
        ),
        '10:56 AM – 12:37 PM',
      );
    });
  });

  group('formatPanchangMomentParts', () {
    test('keeps same-day moments suffix-free', () {
      final parts = formatPanchangMomentParts(
        _bundle('2026-06-12T19:37:00+05:30'),
        panchangDateIso: date,
        format: PanchangTimeFormat.h12,
      );
      expect(parts.time, '07:37 PM');
      expect(parts.dateSuffix, isNull);
    });

    test('splits the date off a next-day moment', () {
      final parts = formatPanchangMomentParts(
        _bundle('2026-06-13T04:06:00+05:30'),
        panchangDateIso: date,
        format: PanchangTimeFormat.h12,
      );
      expect(parts.time, '04:06 AM');
      expect(parts.dateSuffix, 'Jun 13');
    });

    test('needs no suffix in 24+ mode for next-day moments', () {
      final parts = formatPanchangMomentParts(
        _bundle('2026-06-13T01:13:00+05:30'),
        panchangDateIso: date,
        format: PanchangTimeFormat.h24plus,
      );
      expect(parts.time, '25:13');
      expect(parts.dateSuffix, isNull);
    });
  });

  group('formatPanchangRangeParts', () {
    test('marks a midnight-crossing window with an ends suffix', () {
      final window = PanchangWindow(
        start: _bundle('2026-06-12T23:47:00+05:30'),
        end: _bundle('2026-06-13T01:13:00+05:30'),
      );
      final parts = formatPanchangRangeParts(
        window,
        panchangDateIso: date,
        format: PanchangTimeFormat.h12,
      );
      expect(parts.span, '11:47 PM – 01:13 AM');
      expect(parts.dateSuffix, 'ends Jun 13');
    });

    test('collapses matching suffixes when both ends share a date', () {
      final window = PanchangWindow(
        start: _bundle('2026-06-13T00:15:00+05:30'),
        end: _bundle('2026-06-13T00:58:00+05:30'),
      );
      final parts = formatPanchangRangeParts(
        window,
        panchangDateIso: date,
        format: PanchangTimeFormat.h12,
      );
      expect(parts.span, '12:15 AM – 12:58 AM');
      expect(parts.dateSuffix, 'Jun 13');
    });

    test('stays suffix-free in 24+ mode', () {
      final window = PanchangWindow(
        start: _bundle('2026-06-12T23:47:00+05:30'),
        end: _bundle('2026-06-13T01:13:00+05:30'),
      );
      final parts = formatPanchangRangeParts(
        window,
        panchangDateIso: date,
        format: PanchangTimeFormat.h24plus,
      );
      expect(parts.span, '23:47 – 25:13');
      expect(parts.dateSuffix, isNull);
    });
  });
}
