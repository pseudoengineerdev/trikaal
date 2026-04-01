import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/app/state/terminology_mode_state.dart';
import 'package:trikaal_mobile/features/charts/presentation/astrology/kundli_dignity.dart';

void main() {
  group('evaluateGrahaDignity', () {
    test('returns exalted for Sun in Mesha', () {
      final result = evaluateGrahaDignity(grahaKey: 'sun', rashiKey: 'Mesh');

      expect(result.dignity, GrahaDignity.exalted);
      expect(result.labelForMode(TerminologyMode.english), 'Exalted');
      expect(result.labelForMode(TerminologyMode.vedic), 'Uccha');
    });

    test('returns debilitated for Moon in Vrischika', () {
      final result = evaluateGrahaDignity(grahaKey: 'moon', rashiKey: 'Vrsc');

      expect(result.dignity, GrahaDignity.debilitated);
      expect(result.labelForMode(TerminologyMode.english), 'Debilitated');
    });

    test('returns own sign for Budha in Mithuna alias', () {
      final result = evaluateGrahaDignity(grahaKey: 'budha', rashiKey: 'Mith');

      expect(result.dignity, GrahaDignity.ownSign);
      expect(result.labelForMode(TerminologyMode.vedic), 'Swa Rashi');
    });

    test('handles Makar alias normalization for Mangal exaltation', () {
      final result =
          evaluateGrahaDignity(grahaKey: 'mangal', rashiKey: 'Makar');

      expect(result.dignity, GrahaDignity.exalted);
    });

    test('returns not applicable for Rahu and Lagna', () {
      final rahu = evaluateGrahaDignity(grahaKey: 'rahu', rashiKey: 'Mith');
      final lagna = evaluateGrahaDignity(grahaKey: 'lagna', rashiKey: 'Kany');

      expect(rahu.dignity, GrahaDignity.notApplicable);
      expect(lagna.dignity, GrahaDignity.notApplicable);
      expect(rahu.labelForMode(TerminologyMode.english), 'N/A');
    });
  });
}
