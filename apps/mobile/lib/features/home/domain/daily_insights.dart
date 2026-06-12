enum ReadingScope { today, tomorrow, weekly, monthly }

extension ReadingScopeLabels on ReadingScope {
  String get pillLabel {
    switch (this) {
      case ReadingScope.today:
        return 'Today';
      case ReadingScope.tomorrow:
        return 'Tomorrow';
      case ReadingScope.weekly:
        return 'Weekly';
      case ReadingScope.monthly:
        return 'Monthly';
    }
  }

  /// Completes 'Your reading for …' and '… levels'.
  String get phrase {
    switch (this) {
      case ReadingScope.today:
        return 'today';
      case ReadingScope.tomorrow:
        return 'tomorrow';
      case ReadingScope.weekly:
        return 'this week';
      case ReadingScope.monthly:
        return 'this month';
    }
  }
}

/// One "level" on the Today page. Strength is qualitative by design: a tier
/// word plus a 0..1 meter fill — never a percentage. Precise numbers without
/// a real jyotish engine behind them would be the kind of decoration this
/// app refuses to ship.
class DailyMetric {
  const DailyMetric({
    required this.key,
    required this.label,
    required this.glyph,
    required this.basis,
    required this.tierLabel,
    required this.strength,
  });

  final String key;
  final String label;

  /// Graha glyph shown in the card chip (e.g. '♀' for Shukra).
  final String glyph;

  /// The jyotish construct this level will be computed from
  /// (e.g. 'Shukra · 7th bhava').
  final String basis;

  /// Qualitative tier word (e.g. 'Steady', 'Radiant').
  final String tierLabel;

  /// Meter fill, 0..1.
  final double strength;
}

class DailyReading {
  const DailyReading({
    required this.scope,
    required this.text,
    required this.metrics,
  });

  final ReadingScope scope;
  final String text;
  final List<DailyMetric> metrics;
}
