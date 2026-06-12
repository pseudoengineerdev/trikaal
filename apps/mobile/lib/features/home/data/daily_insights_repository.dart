import '../../shared/astrology/sign_trio_insights.dart';
import '../domain/daily_insights.dart';

abstract class DailyInsightsRepository {
  Future<DailyReading> fetchReading({
    required ReadingScope scope,
    required DateTime anchor,
    required SignTrioInsights trio,
  });
}

class _MetricSpec {
  const _MetricSpec({
    required this.key,
    required this.label,
    required this.glyph,
    required this.basis,
  });

  final String key;
  final String label;
  final String glyph;
  final String basis;
}

class _Tier {
  const _Tier(this.label, this.strength);

  final String label;
  final double strength;
}

/// Deterministic preview content until the real jyotish engine lands.
///
/// Honesty rules, so previews never fabricate astrology:
/// - Reading text draws only on the user's actual natal trio (real data) and
///   evergreen guidance — no invented transits, tithis, or nakshatras.
/// - Levels carry the jyotish basis they will eventually be computed from
///   (Tarabala, Chandrabala, bhava activations) and a qualitative tier, but
///   no fake precision. The UI labels them as preview levels.
class PlaceholderDailyInsightsRepository implements DailyInsightsRepository {
  const PlaceholderDailyInsightsRepository();

  /// The six levels, each tied to the construct the future engine computes.
  /// Bhagya is the authentic Vedic counterpart of a "luck factor": the 9th
  /// bhava is fortune itself.
  static const List<_MetricSpec> _metricSpecs = <_MetricSpec>[
    _MetricSpec(
      key: 'bhagya',
      label: 'Fortune',
      glyph: '♃',
      basis: 'Guru · 9th bhava',
    ),
    _MetricSpec(
      key: 'love',
      label: 'Love',
      glyph: '♀',
      basis: 'Shukra · 7th bhava',
    ),
    _MetricSpec(
      key: 'career',
      label: 'Career',
      glyph: '♄',
      basis: 'Shani · 10th bhava',
    ),
    _MetricSpec(
      key: 'mind',
      label: 'Intuition',
      glyph: '☽',
      basis: 'Chandra · Tarabala',
    ),
    _MetricSpec(
      key: 'vitality',
      label: 'Vitality',
      glyph: '☉',
      basis: 'Surya · Lagna',
    ),
    _MetricSpec(
      key: 'gains',
      label: 'Wealth',
      glyph: '☿',
      basis: 'Budha · 11th bhava',
    ),
  ];

  static const List<_Tier> _tiers = <_Tier>[
    _Tier('Tender', 0.32),
    _Tier('Steady', 0.5),
    _Tier('Rising', 0.66),
    _Tier('Strong', 0.82),
    _Tier('Radiant', 0.95),
  ];

  @override
  Future<DailyReading> fetchReading({
    required ReadingScope scope,
    required DateTime anchor,
    required SignTrioInsights trio,
  }) async {
    final daySeed =
        anchor.year * 1000 + _dayOfYear(anchor) + scope.index * 47;
    final signSeed = trio.moon.name.hashCode.abs() % 97;

    final metrics = <DailyMetric>[];
    for (var index = 0; index < _metricSpecs.length; index++) {
      final spec = _metricSpecs[index];
      final tier =
          _tiers[(daySeed + signSeed + index * 31 + spec.key.length) %
              _tiers.length];
      metrics.add(
        DailyMetric(
          key: spec.key,
          label: spec.label,
          glyph: spec.glyph,
          basis: spec.basis,
          tierLabel: tier.label,
          strength: tier.strength,
        ),
      );
    }

    return DailyReading(
      scope: scope,
      text: _readingText(scope, trio, daySeed + signSeed),
      metrics: metrics,
    );
  }

  String _readingText(ReadingScope scope, SignTrioInsights trio, int seed) {
    final moon = trio.moon;
    final rising = trio.rising;
    final moonLine =
        'With your Moon in ${moon.name}, ${_lowerFirst(moon.moonTrait)}';

    final openers = _openersFor(scope);
    final closers = _closersFor(scope);
    final opener = openers[seed % openers.length];
    final closer = closers[(seed ~/ 3) % closers.length];

    return '$opener $moonLine As ${rising.name} rises in your chart, '
        '${_lowerFirst(rising.risingTrait)} $closer';
  }

  List<String> _openersFor(ReadingScope scope) {
    switch (scope) {
      case ReadingScope.today:
        return const <String>[
          'The day rewards deliberate, unhurried moves.',
          'A quietly productive day is within reach.',
          'Today asks for presence more than speed.',
        ];
      case ReadingScope.tomorrow:
        return const <String>[
          'Tomorrow opens with momentum worth preparing for tonight.',
          'Set intentions this evening — tomorrow favors early clarity.',
          'Tomorrow leans toward fresh starts and honest conversations.',
        ];
      case ReadingScope.weekly:
        return const <String>[
          'This week unfolds in chapters — pace yourself through each.',
          'The week favors steady accumulation over single leaps.',
          'A week to consolidate: finish what is nearly done first.',
        ];
      case ReadingScope.monthly:
        return const <String>[
          'This month builds slowly toward something durable.',
          'The month favors roots: habits, savings, and bonds deepen.',
          'A month for alignment — let priorities settle into order.',
        ];
    }
  }

  List<String> _closersFor(ReadingScope scope) {
    switch (scope) {
      case ReadingScope.today:
        return const <String>[
          'Keep the morning for what matters most, and let the evening soften.',
          'One sincere conversation today is worth ten rushed ones.',
          'Small completions now clear the path for bigger beginnings.',
        ];
      case ReadingScope.tomorrow:
        return const <String>[
          'Rest well — clarity tomorrow depends on calm tonight.',
          'Decide tonight what deserves your first hour tomorrow.',
          'Keep tomorrow morning light; depth will find you by afternoon.',
        ];
      case ReadingScope.weekly:
        return const <String>[
          'Guard one quiet day this week for reflection.',
          'Midweek is your hinge — plan the heavier lifts around it.',
          'Let the weekend close loops instead of opening new ones.',
        ];
      case ReadingScope.monthly:
        return const <String>[
          'Revisit your intentions at the full Moon and adjust gently.',
          'What you tend in the first half blooms in the second.',
          'Close the month lighter than you began it.',
        ];
    }
  }

  String _lowerFirst(String text) {
    if (text.isEmpty) {
      return text;
    }
    return text[0].toLowerCase() + text.substring(1);
  }

  int _dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year)).inDays + 1;
  }
}
