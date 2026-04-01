import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/state/terminology_mode_state.dart';
import 'package:trikaal_mobile/features/shared/astrology/term_localizer.dart';

void main() {
  group('Term localizer', () {
    test('returns full Vedic names for abbreviated rashi keys', () {
      expect(localizeRashi('Kany', TerminologyMode.vedic), 'Kanya');
      expect(localizeRashi('Mitu', TerminologyMode.vedic), 'Mithuna');
      expect(localizeRashi('Kumb', TerminologyMode.vedic), 'Kumbha');
    });

    test('returns English equivalents for nakshatra values', () {
      expect(
        localizeNakshatra('Hasta', TerminologyMode.english),
        'Hasta (The Hand)',
      );
      expect(
        localizeNakshatra('Anuradha', TerminologyMode.english),
        'Anuradha (Following Radha)',
      );
      expect(
        localizeNakshatra('U Bhadrapada', TerminologyMode.english),
        'Uttara Bhadrapada (Latter Blessed Feet)',
      );
    });

    test('returns Vedic and English graha names correctly', () {
      expect(localizeGraha('sun', TerminologyMode.vedic), 'Surya');
      expect(localizeGraha('moon', TerminologyMode.vedic), 'Chandra');
      expect(localizeGraha('sun', TerminologyMode.english), 'Sun');
      expect(localizeGraha('moon', TerminologyMode.english), 'Moon');
    });
  });
}
