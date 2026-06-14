import 'package:flutter/material.dart';

/// The classical nature of a planetary hour. In Jyotisha the natural benefics
/// (Jupiter, Venus, Mercury, Moon) make gentle, auspicious hours, while the
/// natural malefics (Sun, Mars, Saturn) make sharp, effortful ones. The hour
/// is not "good" or "bad" by itself — success comes from matching the task to
/// the nature of the ruling graha.
enum HoraNature { benefic, malefic }

/// The interpretive layer for a single planetary hour (hora). The hora maths —
/// the 24 unequal day/night slots and their ruling grahas — already ship from
/// the engine inside the panchang payload; this table adds the meaning the
/// engine deliberately does not encode: each graha's temperament and which
/// activities its hour favours or resists.
@immutable
class HoraInsight {
  const HoraInsight({
    required this.englishName,
    required this.sanskritName,
    required this.glyph,
    required this.nature,
    required this.accent,
    required this.essence,
    required this.goodFor,
    required this.avoid,
  });

  /// English graha name as emitted by the engine (`lord_english`).
  final String englishName;

  /// Sanskrit graha name as emitted by the engine (`lord_vedic`).
  final String sanskritName;

  /// Traditional astronomical glyph for the graha.
  final String glyph;

  final HoraNature nature;

  /// Per-graha accent used for the glyph chip so each hora reads at a glance.
  final Color accent;

  /// One-line temperament of the hour.
  final String essence;

  /// Undertakings the hour supports.
  final List<String> goodFor;

  /// Undertakings better held for a kinder hour.
  final List<String> avoid;

  bool get isBenefic => nature == HoraNature.benefic;

  String get natureLabel => isBenefic ? 'Benefic' : 'Malefic';
}

/// Benefic green / malefic red, reusing the panchang auspicious/inauspicious
/// accents so the Hora feature reads the same as the rest of the app.
const Color horaBeneficColor = Color(0xFF8FE3B0);
const Color horaMaleficColor = Color(0xFFF2A6A1);

Color horaNatureColor(HoraNature nature) =>
    nature == HoraNature.benefic ? horaBeneficColor : horaMaleficColor;

const HoraInsight _surya = HoraInsight(
  englishName: 'Sun',
  sanskritName: 'Surya',
  glyph: '☉',
  nature: HoraNature.malefic,
  accent: Color(0xFFE8C97A),
  essence: 'Vitality, authority and the radiant Self.',
  goodFor: <String>[
    'Dealings with government & officials',
    'Leadership and weighty decisions',
    'Health, vitality and medicine',
    'Interviews, promotions, applications',
    'Meeting elders and the father',
  ],
  avoid: <String>[
    'Borrowing or lending money',
    'Soft, emotional or marital matters',
  ],
);

const HoraInsight _chandra = HoraInsight(
  englishName: 'Moon',
  sanskritName: 'Chandra',
  glyph: '☽',
  nature: HoraNature.benefic,
  accent: Color(0xFFB9D4F1),
  essence: 'The mind, emotions and nurturing flow.',
  goodFor: <String>[
    'Travel, especially over water',
    'Public dealings and networking',
    'Family and domestic matters',
    'Buying liquids, groceries, provisions',
    'Healing and heartfelt conversations',
  ],
  avoid: <String>[
    'Large financial commitments',
    'Confrontation and precision work',
  ],
);

const HoraInsight _mangal = HoraInsight(
  englishName: 'Mars',
  sanskritName: 'Mangal',
  glyph: '♂',
  nature: HoraNature.malefic,
  accent: Color(0xFFEF9A8E),
  essence: 'Courage, energy and decisive action.',
  goodFor: <String>[
    'Sport and physical training',
    'Property, land and construction',
    'Surgery, dental and sharp work',
    'Buying tools, machinery, electronics',
    'Acts of courage and competition',
  ],
  avoid: <String>[
    'Signing agreements and contracts',
    'Marriage talks and diplomacy',
  ],
);

const HoraInsight _budha = HoraInsight(
  englishName: 'Mercury',
  sanskritName: 'Budha',
  glyph: '☿',
  nature: HoraNature.benefic,
  accent: Color(0xFF8FD9A8),
  essence: 'Intellect, speech and exchange.',
  goodFor: <String>[
    'Study, exams and learning skills',
    'Writing, paperwork and contracts',
    'Business, trade and negotiation',
    'Accounts, banking and analysis',
    'Communication and short errands',
  ],
  avoid: <String>[
    'Purely intuitive, emotional choices',
    'Matters needing steady, unwavering resolve',
  ],
);

const HoraInsight _guru = HoraInsight(
  englishName: 'Jupiter',
  sanskritName: 'Guru',
  glyph: '♃',
  nature: HoraNature.benefic,
  accent: Color(0xFFEAB857),
  essence: 'Wisdom, growth and grace — the finest hour.',
  goodFor: <String>[
    'Auspicious new beginnings',
    'Ceremonies, puja and rituals',
    'Education, teaching and counsel',
    'Investments, savings and wealth',
    'Marriage, engagement and charity',
  ],
  avoid: <String>[
    'Greed and over-extension',
    'Unethical shortcuts',
  ],
);

const HoraInsight _shukra = HoraInsight(
  englishName: 'Venus',
  sanskritName: 'Shukra',
  glyph: '♀',
  nature: HoraNature.benefic,
  accent: Color(0xFFE9A6CF),
  essence: 'Love, beauty and pleasure.',
  goodFor: <String>[
    'Marriage, romance and relationships',
    'Arts, music and creativity',
    'Buying jewellery, clothes, luxuries',
    'Vehicles, comforts and décor',
    'Social events and self-care',
  ],
  avoid: <String>[
    'Austerity and harsh labour',
    'Conflict and confrontation',
  ],
);

const HoraInsight _shani = HoraInsight(
  englishName: 'Saturn',
  sanskritName: 'Shani',
  glyph: '♄',
  nature: HoraNature.malefic,
  accent: Color(0xFF9FA0D6),
  essence: 'Discipline, labour and endurance.',
  goodFor: <String>[
    'Long, hard or repetitive labour',
    'Dealings with workers and elders',
    'Real estate, iron, oil and leather',
    'Debt, austerity and detachment',
    'Routine, maintenance and penance',
  ],
  avoid: <String>[
    'Auspicious beginnings and ceremonies',
    'Marriage and joyful travel',
  ],
);

/// All seven classical hora lords, keyed by their English name.
const Map<String, HoraInsight> _byEnglish = <String, HoraInsight>{
  'Sun': _surya,
  'Moon': _chandra,
  'Mars': _mangal,
  'Mercury': _budha,
  'Jupiter': _guru,
  'Venus': _shukra,
  'Saturn': _shani,
};

const Map<String, HoraInsight> _bySanskrit = <String, HoraInsight>{
  'Surya': _surya,
  'Chandra': _chandra,
  'Mangal': _mangal,
  'Budha': _budha,
  'Guru': _guru,
  'Shukra': _shukra,
  'Shani': _shani,
};

const HoraInsight _unknown = HoraInsight(
  englishName: 'Hora',
  sanskritName: 'Hora',
  glyph: '✦',
  nature: HoraNature.benefic,
  accent: Color(0xFFE8C97A),
  essence: 'A planetary hour of the day.',
  goodFor: <String>[],
  avoid: <String>[],
);

/// Resolves the interpretive layer for a hora lord. Accepts either the English
/// (`Sun`) or Sanskrit (`Surya`) name the engine emits, case-insensitively,
/// and never throws — an unrecognised lord yields a neutral placeholder.
HoraInsight horaInsightForLord(String lord) {
  final trimmed = lord.trim();
  final direct = _byEnglish[trimmed] ?? _bySanskrit[trimmed];
  if (direct != null) {
    return direct;
  }
  final lower = trimmed.toLowerCase();
  for (final entry in _byEnglish.entries) {
    if (entry.key.toLowerCase() == lower ||
        entry.value.sanskritName.toLowerCase() == lower) {
      return entry.value;
    }
  }
  return _unknown;
}

/// The seven hora lords in their natural (vara) order, for reference UIs.
const List<HoraInsight> horaLordsInVaraOrder = <HoraInsight>[
  _surya,
  _chandra,
  _mangal,
  _budha,
  _guru,
  _shukra,
  _shani,
];
