import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/hora/domain/hora_insights.dart';

void main() {
  group('horaInsightForLord', () {
    test('resolves all seven classical lords by English name', () {
      const lords = <String>[
        'Sun',
        'Moon',
        'Mars',
        'Mercury',
        'Jupiter',
        'Venus',
        'Saturn',
      ];
      for (final lord in lords) {
        final insight = horaInsightForLord(lord);
        expect(insight.englishName, lord);
        expect(insight.glyph.isNotEmpty, isTrue);
        expect(insight.essence.isNotEmpty, isTrue);
        expect(insight.goodFor, isNotEmpty);
      }
    });

    test('resolves lords by Sanskrit name too', () {
      expect(horaInsightForLord('Shukra').englishName, 'Venus');
      expect(horaInsightForLord('Chandra').englishName, 'Moon');
      expect(horaInsightForLord('Shani').englishName, 'Saturn');
    });

    test('is case-insensitive', () {
      expect(horaInsightForLord('venus').englishName, 'Venus');
      expect(horaInsightForLord('GURU').englishName, 'Jupiter');
    });

    test('classifies natural benefics and malefics correctly', () {
      for (final lord in <String>['Jupiter', 'Venus', 'Mercury', 'Moon']) {
        expect(
          horaInsightForLord(lord).nature,
          HoraNature.benefic,
          reason: '$lord should be benefic',
        );
      }
      for (final lord in <String>['Sun', 'Mars', 'Saturn']) {
        expect(
          horaInsightForLord(lord).nature,
          HoraNature.malefic,
          reason: '$lord should be malefic',
        );
      }
    });

    test('returns a neutral placeholder for an unknown lord (no throw)', () {
      final insight = horaInsightForLord('Rahu');
      expect(insight.englishName, 'Hora');
      expect(insight.goodFor, isEmpty);
    });
  });

  test('horaNatureColor maps nature to the shared accents', () {
    expect(horaNatureColor(HoraNature.benefic), horaBeneficColor);
    expect(horaNatureColor(HoraNature.malefic), horaMaleficColor);
  });

  test('horaLordsInVaraOrder lists all seven grahas in vara order', () {
    expect(horaLordsInVaraOrder, hasLength(7));
    expect(
      horaLordsInVaraOrder.map((HoraInsight i) => i.englishName).toList(),
      <String>['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn'],
    );
  });
}
