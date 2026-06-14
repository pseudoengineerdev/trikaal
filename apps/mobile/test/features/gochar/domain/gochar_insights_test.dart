import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/gochar/domain/gochar_insights.dart';

void main() {
  test('resolves graha insights by key, English or Sanskrit name', () {
    expect(gocharInsightForKey('shani').english, 'Saturn');
    expect(gocharInsightForKey('SHANI').sanskrit, 'Shani');
    expect(gocharInsightForKey('rahu').nature, GrahaNature.shadow);
    expect(gocharInsightForKey('guru').nature, GrahaNature.benefic);
    // Sanskrit/English names resolve too, so dasha labels never fall through.
    expect(gocharInsightForKey('Chandra').english, 'Moon');
    expect(gocharInsightForKey('Surya').english, 'Sun');
    expect(gocharInsightForKey('Moon').sanskrit, 'Chandra');
    expect(gocharInsightForKey('mystery').glyph, '✦');
  });

  test('dasha lord labels resolve, with a non-Graha fallback', () {
    expect(dashaLordLabel('moon', true), 'Chandra');
    expect(dashaLordLabel('moon', false), 'Moon');
    expect(dashaLordLabel('Chandra', false), 'Moon');
    expect(dashaLordLabel(null, true), '—');
    expect(dashaLordLabel('', true), '—');
    // An unrecognised value reads as itself, never the "Graha" placeholder.
    expect(dashaLordLabel('xyz', true), 'Xyz');
  });

  test('bhava themes cover 1..12 and clamp out-of-range', () {
    expect(bhavaTheme(1).title, 'Self');
    expect(bhavaTheme(7).title, 'Partnership');
    expect(bhavaTheme(12).sanskrit, 'Vyaya');
    expect(bhavaTheme(0).house, 1);
    expect(bhavaTheme(99).house, 12);
  });

  test('phala verdict combines favourability and vedha', () {
    expect(
      phalaVerdict(favourable: true, vedhaObstructed: false),
      PhalaVerdict.favourable,
    );
    expect(
      phalaVerdict(favourable: true, vedhaObstructed: true),
      PhalaVerdict.obstructed,
    );
    expect(
      phalaVerdict(favourable: false, vedhaObstructed: false),
      PhalaVerdict.challenging,
    );
    // Not favourable wins even if a (stale) vedha flag is set.
    expect(
      phalaVerdict(favourable: false, vedhaObstructed: true),
      PhalaVerdict.challenging,
    );
  });

  test('dignity labels surface only notable dignities', () {
    expect(isNotableDignity('exalted'), isTrue);
    expect(isNotableDignity('own'), isTrue);
    expect(isNotableDignity('none'), isFalse);
    expect(dignityLabel('debilitated'), 'Debilitated');
    expect(dignitySanskritLabel('exalted'), 'Uccha');
    expect(dignityColor('exalted'), gocharBeneficColor);
    expect(dignityColor('debilitated'), gocharChallengingColor);
  });

  test('ashtakavarga strength labels follow the classical thresholds', () {
    expect(bavStrengthLabel(6), 'Strong');
    expect(bavStrengthLabel(4), 'Moderate');
    expect(bavStrengthLabel(1), 'Weak');
    expect(savStrengthLabel(34), 'Auspicious sign');
    expect(savStrengthLabel(27), 'Balanced sign');
    expect(savStrengthLabel(20), 'Strained sign');
  });

  test('saturn labels map status and phase', () {
    expect(saturnStatusLabel('sade_sati'), 'Sade Sati');
    expect(saturnStatusLabel('ashtama_dhaiya'), 'Ashtama Shani');
    expect(saturnStatusLabel('none'), 'Clear of Sade Sati');
    expect(saturnPhaseLabel('peak'), 'Peak phase');
    expect(saturnPhaseLabel(null), '');
  });

  test('motion labels translate between modes', () {
    expect(motionLabel('retrograde'), 'Retrograde');
    expect(motionSanskritLabel('retrograde'), 'Vakri');
    expect(motionLabel('direct'), 'Direct');
    expect(motionSanskritLabel('direct'), 'Margi');
  });
}
