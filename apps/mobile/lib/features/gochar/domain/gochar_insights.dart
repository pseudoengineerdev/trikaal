import 'package:flutter/material.dart';

/// The interpretive layer for Gochar (planetary transits). The astronomy — live
/// positions, houses from the Moon/Lagna, ingress and station dates, Sade Sati
/// windows and Ashtakavarga bindus — all ship from the backend. This file adds
/// the meaning the engine deliberately does not encode: each graha's temperament
/// and glyph, the twelve bhava themes a transit lights up, and the plain reading
/// of the classical verdicts (phala, vedha, dignity, motion, strength).
enum GrahaNature { benefic, malefic, shadow }

@immutable
class GrahaTransitInsight {
  const GrahaTransitInsight({
    required this.key,
    required this.english,
    required this.sanskrit,
    required this.glyph,
    required this.nature,
    required this.accent,
    required this.essence,
  });

  final String key;
  final String english;
  final String sanskrit;
  final String glyph;
  final GrahaNature nature;
  final Color accent;

  /// One line on what this graha's transit stirs, wherever it lands.
  final String essence;

  String get natureLabel => switch (nature) {
        GrahaNature.benefic => 'Benefic',
        GrahaNature.malefic => 'Malefic',
        GrahaNature.shadow => 'Shadow',
      };
}

// Shared accent palette — kept in step with the Hora feature so a graha reads
// the same colour across the app.
const Color gocharBeneficColor = Color(0xFF8FE3B0);
const Color gocharChallengingColor = Color(0xFFF2A6A1);
const Color gocharObstructedColor = Color(0xFFE8C97A);
const Color gocharNeutralColor = Color(0xFFB7C2D8);

const Map<String, GrahaTransitInsight> _byKey = <String, GrahaTransitInsight>{
  'sun': GrahaTransitInsight(
    key: 'sun',
    english: 'Sun',
    sanskrit: 'Surya',
    glyph: '☉',
    nature: GrahaNature.malefic,
    accent: Color(0xFFE8C97A),
    essence: 'Authority, vitality and recognition come into focus.',
  ),
  'moon': GrahaTransitInsight(
    key: 'moon',
    english: 'Moon',
    sanskrit: 'Chandra',
    glyph: '☽',
    nature: GrahaNature.benefic,
    accent: Color(0xFFB9D4F1),
    essence: 'Mood, public life and daily needs shift quickly.',
  ),
  'mangal': GrahaTransitInsight(
    key: 'mangal',
    english: 'Mars',
    sanskrit: 'Mangal',
    glyph: '♂',
    nature: GrahaNature.malefic,
    accent: Color(0xFFEF9A8E),
    essence: 'Drive, courage and friction are stirred into action.',
  ),
  'budha': GrahaTransitInsight(
    key: 'budha',
    english: 'Mercury',
    sanskrit: 'Budha',
    glyph: '☿',
    nature: GrahaNature.benefic,
    accent: Color(0xFF8FD9A8),
    essence: 'Communication, trade, study and travel are activated.',
  ),
  'guru': GrahaTransitInsight(
    key: 'guru',
    english: 'Jupiter',
    sanskrit: 'Guru',
    glyph: '♃',
    nature: GrahaNature.benefic,
    accent: Color(0xFFEAB857),
    essence: 'Growth, fortune and wisdom expand this area of life.',
  ),
  'shukra': GrahaTransitInsight(
    key: 'shukra',
    english: 'Venus',
    sanskrit: 'Shukra',
    glyph: '♀',
    nature: GrahaNature.benefic,
    accent: Color(0xFFE9A6CF),
    essence: 'Love, comfort, art and pleasure are favoured here.',
  ),
  'shani': GrahaTransitInsight(
    key: 'shani',
    english: 'Saturn',
    sanskrit: 'Shani',
    glyph: '♄',
    nature: GrahaNature.malefic,
    accent: Color(0xFF9FA0D6),
    essence: 'Discipline, patience and hard lessons are tested.',
  ),
  'rahu': GrahaTransitInsight(
    key: 'rahu',
    english: 'Rahu',
    sanskrit: 'Rahu',
    glyph: '☊',
    nature: GrahaNature.shadow,
    accent: Color(0xFFB69CE0),
    essence: 'Ambition, obsession and the unconventional surge.',
  ),
  'ketu': GrahaTransitInsight(
    key: 'ketu',
    english: 'Ketu',
    sanskrit: 'Ketu',
    glyph: '☋',
    nature: GrahaNature.shadow,
    accent: Color(0xFFC2A38C),
    essence: 'Detachment, endings and inner seeking deepen.',
  ),
};

const GrahaTransitInsight _unknown = GrahaTransitInsight(
  key: 'graha',
  english: 'Graha',
  sanskrit: 'Graha',
  glyph: '✦',
  nature: GrahaNature.benefic,
  accent: Color(0xFFE8C97A),
  essence: 'A transiting graha.',
);

/// Resolves a graha by its engine key (`moon`), English name (`Moon`) or
/// Sanskrit name (`Chandra`), case-insensitively. Never throws; an unknown value
/// yields the neutral placeholder.
GrahaTransitInsight gocharInsightForKey(String key) {
  final normalized = key.trim().toLowerCase();
  final direct = _byKey[normalized];
  if (direct != null) {
    return direct;
  }
  for (final insight in _byKey.values) {
    if (insight.sanskrit.toLowerCase() == normalized ||
        insight.english.toLowerCase() == normalized) {
      return insight;
    }
  }
  return _unknown;
}

/// The twelve bhava themes a transit can light up. Used for both the Moon and
/// Lagna reference frames.
@immutable
class BhavaTheme {
  const BhavaTheme({
    required this.house,
    required this.sanskrit,
    required this.title,
    required this.areas,
  });

  final int house;
  final String sanskrit;
  final String title;
  final String areas;
}

const List<BhavaTheme> _bhavaThemes = <BhavaTheme>[
  BhavaTheme(house: 1, sanskrit: 'Tanu', title: 'Self', areas: 'body, vitality, identity'),
  BhavaTheme(house: 2, sanskrit: 'Dhana', title: 'Wealth', areas: 'savings, speech, family'),
  BhavaTheme(house: 3, sanskrit: 'Sahaja', title: 'Courage', areas: 'effort, siblings, skills'),
  BhavaTheme(house: 4, sanskrit: 'Sukha', title: 'Home', areas: 'comfort, mother, property'),
  BhavaTheme(house: 5, sanskrit: 'Putra', title: 'Creativity', areas: 'children, learning, romance'),
  BhavaTheme(house: 6, sanskrit: 'Ripu', title: 'Service', areas: 'health, work, obstacles'),
  BhavaTheme(house: 7, sanskrit: 'Yuvati', title: 'Partnership', areas: 'marriage, trade, others'),
  BhavaTheme(house: 8, sanskrit: 'Randhra', title: 'Change', areas: 'transformation, secrets, depth'),
  BhavaTheme(house: 9, sanskrit: 'Dharma', title: 'Fortune', areas: 'faith, gurus, long travel'),
  BhavaTheme(house: 10, sanskrit: 'Karma', title: 'Career', areas: 'status, action, public role'),
  BhavaTheme(house: 11, sanskrit: 'Labha', title: 'Gains', areas: 'income, networks, fulfilment'),
  BhavaTheme(house: 12, sanskrit: 'Vyaya', title: 'Release', areas: 'expense, retreat, moksha'),
];

BhavaTheme bhavaTheme(int house) {
  final clamped = house.clamp(1, 12);
  return _bhavaThemes[clamped - 1];
}

// --------------------------------------------------------------------------- //
// Plain readings of the classical verdicts
// --------------------------------------------------------------------------- //
String motionLabel(String motion) => switch (motion) {
      'retrograde' => 'Retrograde',
      'stationary' => 'Stationary',
      _ => 'Direct',
    };

String motionSanskritLabel(String motion) => switch (motion) {
      'retrograde' => 'Vakri',
      'stationary' => 'Stambhi',
      _ => 'Margi',
    };

/// Label for the next *station* (motion reversal), named by the direction it
/// will turn — a station is a change of direction, not a change of sign, and a
/// planet stations several times within one sign.
String nextStationLabel(String currentMotion) => switch (currentMotion) {
      'direct' => 'Turns retrograde',
      'retrograde' => 'Turns direct',
      _ => 'Next station',
    };

String dignityLabel(String dignity) => switch (dignity) {
      'exalted' => 'Exalted',
      'debilitated' => 'Debilitated',
      'moolatrikona' => 'Moolatrikona',
      'own' => 'Own sign',
      _ => '',
    };

String dignitySanskritLabel(String dignity) => switch (dignity) {
      'exalted' => 'Uccha',
      'debilitated' => 'Neecha',
      'moolatrikona' => 'Moolatrikona',
      'own' => 'Swakshetra',
      _ => '',
    };

/// True for dignities worth surfacing as a chip.
bool isNotableDignity(String dignity) => dignityLabel(dignity).isNotEmpty;

Color dignityColor(String dignity) => switch (dignity) {
      'exalted' || 'moolatrikona' || 'own' => gocharBeneficColor,
      'debilitated' => gocharChallengingColor,
      _ => gocharNeutralColor,
    };

/// The four-way transit verdict combining the classical favourable-house rule
/// with the Vedha obstruction.
enum PhalaVerdict { favourable, obstructed, challenging }

PhalaVerdict phalaVerdict({
  required bool favourable,
  required bool vedhaObstructed,
}) {
  if (!favourable) {
    return PhalaVerdict.challenging;
  }
  return vedhaObstructed ? PhalaVerdict.obstructed : PhalaVerdict.favourable;
}

String phalaLabel(PhalaVerdict verdict) => switch (verdict) {
      PhalaVerdict.favourable => 'Favourable',
      PhalaVerdict.obstructed => 'Obstructed',
      PhalaVerdict.challenging => 'Challenging',
    };

Color phalaColor(PhalaVerdict verdict) => switch (verdict) {
      PhalaVerdict.favourable => gocharBeneficColor,
      PhalaVerdict.obstructed => gocharObstructedColor,
      PhalaVerdict.challenging => gocharChallengingColor,
    };

// --------------------------------------------------------------------------- //
// Ashtakavarga strength reads
// --------------------------------------------------------------------------- //
/// Bhinnashtakavarga (0-8): the planet's own support in its transit sign.
String bavStrengthLabel(int bindus) {
  if (bindus >= 5) {
    return 'Strong';
  }
  if (bindus >= 3) {
    return 'Moderate';
  }
  return 'Weak';
}

Color bavStrengthColor(int bindus) {
  if (bindus >= 5) {
    return gocharBeneficColor;
  }
  if (bindus >= 3) {
    return gocharObstructedColor;
  }
  return gocharChallengingColor;
}

/// Sarvashtakavarga (per sign, averages ~28; the 12 signs total 337).
String savStrengthLabel(int sarva) {
  if (sarva >= 30) {
    return 'Auspicious sign';
  }
  if (sarva >= 25) {
    return 'Balanced sign';
  }
  return 'Strained sign';
}

// --------------------------------------------------------------------------- //
// Jupiter-Saturn double transit labels
// --------------------------------------------------------------------------- //
/// How a graha touches a sign — its occupancy or graha-drishti aspect.
String aspectRelationLabel(String relation) => switch (relation) {
      'occupies' => 'occupies',
      'aspect_3' => '3rd aspect',
      'aspect_5' => '5th aspect',
      'aspect_7' => '7th aspect',
      'aspect_9' => '9th aspect',
      'aspect_10' => '10th aspect',
      _ => '',
    };

/// Plain label for a bhava's double-transit tier. "Event window" means the
/// double transit hits the bhava from both Lagna and Moon AND the running dasha
/// agrees — the classical fructifying combination.
String doubleTransitTierLabel(String tier) => switch (tier) {
      'event' => 'Event window',
      'strong' => 'Strong transit',
      'building' => 'Building',
      'mild' => 'Mild',
      _ => 'Quiet',
    };

Color doubleTransitTierColor(String tier) => switch (tier) {
      'event' => gocharBeneficColor,
      'strong' => gocharObstructedColor,
      'building' => gocharObstructedColor,
      'mild' => gocharNeutralColor,
      _ => gocharNeutralColor,
    };

/// Sanskrit/English label for a dasha lord key (e.g. shown in the dasha gate).
/// Falls back to the raw value (never the neutral "Graha" placeholder) so an
/// unexpected key still reads sensibly.
String dashaLordLabel(String? key, bool sanskrit) {
  if (key == null || key.trim().isEmpty) {
    return '—';
  }
  final insight = gocharInsightForKey(key);
  if (identical(insight, _unknown)) {
    final raw = key.trim();
    return raw[0].toUpperCase() + raw.substring(1);
  }
  return sanskrit ? insight.sanskrit : insight.english;
}

// --------------------------------------------------------------------------- //
// Sade Sati / Dhaiya labels
// --------------------------------------------------------------------------- //
String saturnStatusLabel(String status) => switch (status) {
      'sade_sati' => 'Sade Sati',
      'kantaka_dhaiya' => 'Kantaka Shani',
      'ashtama_dhaiya' => 'Ashtama Shani',
      _ => 'Clear of Sade Sati',
    };

String saturnPhaseLabel(String? phase) => switch (phase) {
      'rising' => 'Rising phase',
      'peak' => 'Peak phase',
      'setting' => 'Setting phase',
      _ => '',
    };

String saturnPhaseSubtitle(String phase) => switch (phase) {
      'rising' => '12th from Moon · the build-up',
      'peak' => 'Over the Moon · the most intense leg',
      'setting' => '2nd from Moon · the easing-off',
      _ => '',
    };

String saturnStatusBlurb(String status) => switch (status) {
      'sade_sati' =>
        "Saturn's 7½-year passage over the 12th, 1st and 2nd from your Moon — a "
            'long season of pruning, responsibility and maturing.',
      'kantaka_dhaiya' =>
        "Saturn's 2½-year transit of the 4th from your Moon (Ardhashtama). It "
            'presses on home, peace of mind and inner contentment.',
      'ashtama_dhaiya' =>
        "Saturn's 2½-year transit of the 8th from your Moon — a Dhaiya that asks "
            'for caution with health, change and shared resources.',
      _ =>
        'Saturn is not transiting the sensitive houses from your Moon, so neither '
            'Sade Sati nor a Dhaiya is running right now.',
    };
