import '../../../../app/state/terminology_mode_state.dart';

enum GrahaDignity {
  exalted,
  debilitated,
  ownSign,
  neutral,
  notApplicable,
}

class GrahaDignityResult {
  const GrahaDignityResult({
    required this.dignity,
    required this.englishLabel,
    required this.vedicLabel,
  });

  final GrahaDignity dignity;
  final String englishLabel;
  final String vedicLabel;

  String labelForMode(TerminologyMode mode) {
    return mode == TerminologyMode.vedic ? vedicLabel : englishLabel;
  }
}

GrahaDignityResult evaluateGrahaDignity({
  required String grahaKey,
  required String rashiKey,
}) {
  final normalizedGraha = grahaKey.trim().toLowerCase();
  final normalizedRashi = _normalizeRashi(rashiKey);
  final rule = _dignityRules[normalizedGraha];
  if (rule == null) {
    return _dignityResult(GrahaDignity.notApplicable);
  }
  if (rule.notApplicable) {
    return _dignityResult(GrahaDignity.notApplicable);
  }
  if (rule.exaltedRashi == normalizedRashi) {
    return _dignityResult(GrahaDignity.exalted);
  }
  if (rule.debilitatedRashi == normalizedRashi) {
    return _dignityResult(GrahaDignity.debilitated);
  }
  if (rule.ownRashi.contains(normalizedRashi)) {
    return _dignityResult(GrahaDignity.ownSign);
  }
  return _dignityResult(GrahaDignity.neutral);
}

GrahaDignityResult _dignityResult(GrahaDignity dignity) {
  return switch (dignity) {
    GrahaDignity.exalted => const GrahaDignityResult(
        dignity: GrahaDignity.exalted,
        englishLabel: 'Exalted',
        vedicLabel: 'Uccha',
      ),
    GrahaDignity.debilitated => const GrahaDignityResult(
        dignity: GrahaDignity.debilitated,
        englishLabel: 'Debilitated',
        vedicLabel: 'Neecha',
      ),
    GrahaDignity.ownSign => const GrahaDignityResult(
        dignity: GrahaDignity.ownSign,
        englishLabel: 'Own Sign',
        vedicLabel: 'Swa Rashi',
      ),
    GrahaDignity.neutral => const GrahaDignityResult(
        dignity: GrahaDignity.neutral,
        englishLabel: 'Neutral',
        vedicLabel: 'Sama',
      ),
    GrahaDignity.notApplicable => const GrahaDignityResult(
        dignity: GrahaDignity.notApplicable,
        englishLabel: 'N/A',
        vedicLabel: 'N/A',
      ),
  };
}

String _normalizeRashi(String raw) {
  final key = raw.trim();
  if (key == 'Makar') {
    return 'Maka';
  }
  if (key == 'Mith') {
    return 'Mitu';
  }
  return key;
}

class _GrahaDignityRule {
  const _GrahaDignityRule({
    this.exaltedRashi = '',
    this.debilitatedRashi = '',
    this.ownRashi = const <String>{},
    this.notApplicable = false,
  });

  final String exaltedRashi;
  final String debilitatedRashi;
  final Set<String> ownRashi;
  final bool notApplicable;
}

const Map<String, _GrahaDignityRule> _dignityRules =
    <String, _GrahaDignityRule>{
  'sun': _GrahaDignityRule(
    exaltedRashi: 'Mesh',
    debilitatedRashi: 'Tula',
    ownRashi: <String>{'Simh'},
  ),
  'moon': _GrahaDignityRule(
    exaltedRashi: 'Vrish',
    debilitatedRashi: 'Vrsc',
    ownRashi: <String>{'Kark'},
  ),
  'mangal': _GrahaDignityRule(
    exaltedRashi: 'Maka',
    debilitatedRashi: 'Kark',
    ownRashi: <String>{'Mesh', 'Vrsc'},
  ),
  'budha': _GrahaDignityRule(
    exaltedRashi: 'Kany',
    debilitatedRashi: 'Meen',
    ownRashi: <String>{'Mitu', 'Kany'},
  ),
  'guru': _GrahaDignityRule(
    exaltedRashi: 'Kark',
    debilitatedRashi: 'Maka',
    ownRashi: <String>{'Dhanu', 'Meen'},
  ),
  'shukra': _GrahaDignityRule(
    exaltedRashi: 'Meen',
    debilitatedRashi: 'Kany',
    ownRashi: <String>{'Vrish', 'Tula'},
  ),
  'shani': _GrahaDignityRule(
    exaltedRashi: 'Tula',
    debilitatedRashi: 'Mesh',
    ownRashi: <String>{'Maka', 'Kumb'},
  ),
  'rahu': _GrahaDignityRule(notApplicable: true),
  'ketu': _GrahaDignityRule(notApplicable: true),
  'spashth_rahu': _GrahaDignityRule(notApplicable: true),
  'spashth_ketu': _GrahaDignityRule(notApplicable: true),
  'lagna': _GrahaDignityRule(notApplicable: true),
};
