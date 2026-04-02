class RashiInsight {
  const RashiInsight({
    required this.code,
    required this.name,
    required this.symbol,
    required this.sunTrait,
    required this.moonTrait,
    required this.risingTrait,
    required this.element,
    required this.modality,
    required this.polarity,
  });

  final String code;
  final String name;
  final String symbol;
  final String sunTrait;
  final String moonTrait;
  final String risingTrait;
  final String element;
  final String modality;
  final String polarity;
}

const Map<String, String> _aliases = <String, String>{
  'Maka': 'Makar',
  'Mith': 'Mitu',
};

const Map<String, RashiInsight> _insights = <String, RashiInsight>{
  'Mesh': RashiInsight(
    code: 'Mesh',
    name: 'Aries',
    symbol: '♈',
    sunTrait: 'You lead with bold initiative and fearless momentum.',
    moonTrait: 'Your emotions move fast and prefer direct honesty.',
    risingTrait: 'People see you as confident, brave, and action-first.',
    element: 'Fire',
    modality: 'Cardinal',
    polarity: 'Masculine',
  ),
  'Vrish': RashiInsight(
    code: 'Vrish',
    name: 'Taurus',
    symbol: '♉',
    sunTrait: 'You are grounded, patient, and value lasting stability.',
    moonTrait: 'You seek emotional safety through comfort and consistency.',
    risingTrait: 'People see you as steady, calm, and dependable.',
    element: 'Earth',
    modality: 'Fixed',
    polarity: 'Feminine',
  ),
  'Mitu': RashiInsight(
    code: 'Mitu',
    name: 'Gemini',
    symbol: '♊',
    sunTrait: 'You shine through curiosity, ideas, and quick learning.',
    moonTrait: 'Your inner world needs variety, words, and mental clarity.',
    risingTrait: 'People see you as witty, bright, and social.',
    element: 'Air',
    modality: 'Mutable',
    polarity: 'Masculine',
  ),
  'Kark': RashiInsight(
    code: 'Kark',
    name: 'Cancer',
    symbol: '♋',
    sunTrait: 'You are nurturing, intuitive, and deeply protective.',
    moonTrait: 'Your emotional depth is strong, empathetic, and memory-rich.',
    risingTrait: 'People see you as caring, soft, and emotionally aware.',
    element: 'Water',
    modality: 'Cardinal',
    polarity: 'Feminine',
  ),
  'Simh': RashiInsight(
    code: 'Simh',
    name: 'Leo',
    symbol: '♌',
    sunTrait: 'You express heart, creativity, and generous confidence.',
    moonTrait: 'Emotionally, you need warmth, pride, and appreciation.',
    risingTrait: 'People see you as radiant, expressive, and charismatic.',
    element: 'Fire',
    modality: 'Fixed',
    polarity: 'Masculine',
  ),
  'Kany': RashiInsight(
    code: 'Kany',
    name: 'Virgo',
    symbol: '♍',
    sunTrait: 'You thrive by improving systems with care and precision.',
    moonTrait: 'Your emotions process through order, service, and usefulness.',
    risingTrait: 'People see you as thoughtful, practical, and detail-aware.',
    element: 'Earth',
    modality: 'Mutable',
    polarity: 'Feminine',
  ),
  'Tula': RashiInsight(
    code: 'Tula',
    name: 'Libra',
    symbol: '♎',
    sunTrait: 'You seek harmony, fairness, and aesthetic balance.',
    moonTrait: 'Your inner peace comes from connection and emotional symmetry.',
    risingTrait: 'People see you as graceful, social, and diplomatic.',
    element: 'Air',
    modality: 'Cardinal',
    polarity: 'Masculine',
  ),
  'Vrsc': RashiInsight(
    code: 'Vrsc',
    name: 'Scorpio',
    symbol: '♏',
    sunTrait: 'You carry intensity, depth, and transformative focus.',
    moonTrait: 'Emotionally, you are private, loyal, and all-in.',
    risingTrait: 'People see you as magnetic, mysterious, and powerful.',
    element: 'Water',
    modality: 'Fixed',
    polarity: 'Feminine',
  ),
  'Dhanu': RashiInsight(
    code: 'Dhanu',
    name: 'Sagittarius',
    symbol: '♐',
    sunTrait: 'You grow through truth, adventure, and expansive thinking.',
    moonTrait: 'Your emotions need freedom, meaning, and perspective.',
    risingTrait: 'People see you as open, optimistic, and bold.',
    element: 'Fire',
    modality: 'Mutable',
    polarity: 'Masculine',
  ),
  'Makar': RashiInsight(
    code: 'Makar',
    name: 'Capricorn',
    symbol: '♑',
    sunTrait: 'You build patiently with ambition, discipline, and integrity.',
    moonTrait:
        'Emotionally, you stabilize through responsibility and progress.',
    risingTrait: 'People see you as composed, mature, and reliable.',
    element: 'Earth',
    modality: 'Cardinal',
    polarity: 'Feminine',
  ),
  'Kumb': RashiInsight(
    code: 'Kumb',
    name: 'Aquarius',
    symbol: '♒',
    sunTrait: 'You stand out through originality, ideas, and future vision.',
    moonTrait: 'Your emotional style values space, ideals, and independence.',
    risingTrait: 'People see you as unique, progressive, and unconventional.',
    element: 'Air',
    modality: 'Fixed',
    polarity: 'Masculine',
  ),
  'Meen': RashiInsight(
    code: 'Meen',
    name: 'Pisces',
    symbol: '♓',
    sunTrait: 'You lead with imagination, compassion, and spiritual depth.',
    moonTrait: 'Emotionally, you are porous, dreamy, and deeply empathetic.',
    risingTrait: 'People see you as gentle, mystical, and kind-hearted.',
    element: 'Water',
    modality: 'Mutable',
    polarity: 'Feminine',
  ),
};

RashiInsight rashiInsightFor(String rawCode) {
  final canonical = _aliases[rawCode] ?? rawCode;
  return _insights[canonical] ??
      const RashiInsight(
        code: 'unknown',
        name: 'Unknown',
        symbol: '✦',
        sunTrait: 'Your core personality is still being decoded.',
        moonTrait: 'Your emotional style is still being decoded.',
        risingTrait: 'Your outward style is still being decoded.',
        element: '—',
        modality: '—',
        polarity: '—',
      );
}
