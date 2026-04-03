import '../../charts/data/models/compute_report_models.dart';
import '../../dasha/data/models/dasha_models.dart';
import '../../home/presentation/astrology/rashi_insights.dart';

const List<String> _dominanceGrahaKeys = <String>[
  'sun',
  'moon',
  'mangal',
  'budha',
  'guru',
  'shukra',
  'shani',
  'rahu',
  'ketu',
  'lagna',
];

const List<String> _rashiOrder = <String>[
  'Mesh',
  'Vrish',
  'Mitu',
  'Kark',
  'Simh',
  'Kany',
  'Tula',
  'Vrsc',
  'Dhanu',
  'Makar',
  'Kumb',
  'Meen',
];

const Map<String, String> _rashiAliases = <String, String>{
  'Maka': 'Makar',
  'Mith': 'Mitu',
};

const Map<String, String> _rashiLords = <String, String>{
  'Mesh': 'mangal',
  'Vrish': 'shukra',
  'Mitu': 'budha',
  'Kark': 'moon',
  'Simh': 'sun',
  'Kany': 'budha',
  'Tula': 'shukra',
  'Vrsc': 'mangal',
  'Dhanu': 'guru',
  'Makar': 'shani',
  'Kumb': 'shani',
  'Meen': 'guru',
};

const Map<String, Set<String>> _grahaOwnSigns = <String, Set<String>>{
  'sun': <String>{'Simh'},
  'moon': <String>{'Kark'},
  'mangal': <String>{'Mesh', 'Vrsc'},
  'budha': <String>{'Mitu', 'Kany'},
  'guru': <String>{'Dhanu', 'Meen'},
  'shukra': <String>{'Vrish', 'Tula'},
  'shani': <String>{'Makar', 'Kumb'},
};

const Map<String, String> _grahaMooltrikonaSign = <String, String>{
  'sun': 'Simh',
  'moon': 'Vrish',
  'mangal': 'Mesh',
  'budha': 'Kany',
  'guru': 'Dhanu',
  'shukra': 'Tula',
  'shani': 'Kumb',
};

const Map<String, String> _grahaExaltationSign = <String, String>{
  'sun': 'Mesh',
  'moon': 'Vrish',
  'mangal': 'Makar',
  'budha': 'Kany',
  'guru': 'Kark',
  'shukra': 'Meen',
  'shani': 'Tula',
};

const Map<String, String> _grahaDebilitationSign = <String, String>{
  'sun': 'Tula',
  'moon': 'Vrsc',
  'mangal': 'Kark',
  'budha': 'Meen',
  'guru': 'Makar',
  'shukra': 'Kany',
  'shani': 'Mesh',
};

const Map<String, Set<String>> _grahaFriends = <String, Set<String>>{
  'sun': <String>{'moon', 'mangal', 'guru'},
  'moon': <String>{'sun', 'budha'},
  'mangal': <String>{'sun', 'moon', 'guru'},
  'budha': <String>{'sun', 'shukra'},
  'guru': <String>{'sun', 'moon', 'mangal'},
  'shukra': <String>{'budha', 'shani'},
  'shani': <String>{'budha', 'shukra'},
};

const Map<String, Set<String>> _grahaNeutrals = <String, Set<String>>{
  'sun': <String>{'budha'},
  'moon': <String>{'mangal', 'guru', 'shukra', 'shani'},
  'mangal': <String>{'shukra', 'shani'},
  'budha': <String>{'mangal', 'guru', 'shani'},
  'guru': <String>{'shani'},
  'shukra': <String>{'mangal', 'guru'},
  'shani': <String>{'mangal', 'guru'},
};

const Map<String, Set<String>> _grahaEnemies = <String, Set<String>>{
  'sun': <String>{'shukra', 'shani'},
  'moon': <String>{},
  'mangal': <String>{'budha'},
  'budha': <String>{'moon'},
  'guru': <String>{'budha', 'shukra'},
  'shukra': <String>{'sun', 'moon'},
  'shani': <String>{'sun', 'moon'},
};

const Map<String, String> _dashaLordAlias = <String, String>{
  'sun': 'sun',
  'surya': 'sun',
  'moon': 'moon',
  'chandra': 'moon',
  'mars': 'mangal',
  'mangal': 'mangal',
  'mangala': 'mangal',
  'mercury': 'budha',
  'budha': 'budha',
  'jupiter': 'guru',
  'guru': 'guru',
  'brihaspati': 'guru',
  'venus': 'shukra',
  'shukra': 'shukra',
  'saturn': 'shani',
  'shani': 'shani',
  'rahu': 'rahu',
  'ketu': 'ketu',
  'lagna': 'lagna',
  'ascendant': 'lagna',
};

const Set<int> _kendraHouses = <int>{1, 4, 7, 10};
const Set<int> _trikonaHouses = <int>{1, 5, 9};
const Set<int> _upachayaHouses = <int>{3, 6, 10, 11};
const Set<int> _dusthanaHouses = <int>{6, 8, 12};

class VedicDominanceSnapshot {
  const VedicDominanceSnapshot({
    required this.grahaScores,
    required this.elementScores,
    required this.mahaDashaLordKey,
    required this.antarDashaLordKey,
  });

  final List<VedicGrahaDominance> grahaScores;
  final List<VedicElementDominance> elementScores;
  final String? mahaDashaLordKey;
  final String? antarDashaLordKey;

  VedicGrahaDominance get strongestGraha => grahaScores.first;
  VedicElementDominance get strongestElement => elementScores.first;
}

class VedicGrahaDominance {
  const VedicGrahaDominance({
    required this.grahaKey,
    required this.house,
    required this.rashi,
    required this.totalPoints,
    required this.dominantPercent,
    required this.basePoints,
    required this.placementPoints,
    required this.lordshipPoints,
    required this.housePoints,
    required this.navamsaPoints,
    required this.dignityPoints,
    required this.motionPoints,
    required this.conditionPoints,
    required this.dashaPoints,
    required this.dignityTag,
    required this.mahaDashaActive,
    required this.antarDashaActive,
  });

  final String grahaKey;
  final int house;
  final String rashi;
  final int totalPoints;
  final double dominantPercent;
  final int basePoints;
  final int placementPoints;
  final int lordshipPoints;
  final int housePoints;
  final int navamsaPoints;
  final int dignityPoints;
  final int motionPoints;
  final int conditionPoints;
  final int dashaPoints;
  final String dignityTag;
  final bool mahaDashaActive;
  final bool antarDashaActive;
}

class VedicElementDominance {
  const VedicElementDominance({
    required this.element,
    required this.points,
    required this.placements,
    required this.percent,
  });

  final String element;
  final double points;
  final int placements;
  final double percent;
}

VedicDominanceSnapshot computeVedicDominanceSnapshot({
  required ReportGrahaTable grahaTable,
  required DashaSummary dasha,
}) {
  final mahaDashaLordKey = _resolveMahaDashaLordKey(dasha);
  final antarDashaLordKey = _resolveAntarDashaLordKey(dasha);
  final lagnaRashi = _normalizeRashi(grahaTable.lagna.rashi);
  final houseLordPointsByGraha = _computeHouseLordPointsFromLagna(lagnaRashi);

  final scores = _dominanceGrahaKeys.map((grahaKey) {
    final entry = grahaTable.entryByKey(grahaKey);

    final basePoints = _basePresencePoints(grahaKey);
    final placementPoints = _housePlacementPoints(entry.house, grahaKey);
    final lordshipPoints = houseLordPointsByGraha[grahaKey] ?? 0;
    final housePoints = placementPoints + lordshipPoints;
    final dignity = _dignityAssessment(grahaKey, entry.rashi);
    final navamsaDignity = _dignityAssessment(grahaKey, entry.d9Rashi);
    final navamsaPoints = _navamsaDignityPoints(navamsaDignity.status);
    final dignityPoints = dignity.points + navamsaPoints;
    final motionPoints = _motionPoints(entry.retrograde, grahaKey);
    final conditionPoints = _conditionPoints(entry.combust, grahaKey);
    final dashaPoints = _dashaBoost(
      grahaKey: grahaKey,
      mahaDashaLordKey: mahaDashaLordKey,
      antarDashaLordKey: antarDashaLordKey,
    );

    final total = _clampMinimum(
      basePoints +
          housePoints +
          dignityPoints +
          motionPoints +
          conditionPoints +
          dashaPoints,
      1,
    );

    return VedicGrahaDominance(
      grahaKey: grahaKey,
      house: entry.house,
      rashi: entry.rashi,
      totalPoints: total,
      dominantPercent: 0,
      basePoints: basePoints,
      placementPoints: placementPoints,
      lordshipPoints: lordshipPoints,
      housePoints: housePoints,
      navamsaPoints: navamsaPoints,
      dignityPoints: dignityPoints,
      motionPoints: motionPoints,
      conditionPoints: conditionPoints,
      dashaPoints: dashaPoints,
      dignityTag: dignity.tag,
      mahaDashaActive: grahaKey == mahaDashaLordKey,
      antarDashaActive: grahaKey == antarDashaLordKey,
    );
  }).toList(growable: false);

  final totalPoints =
      scores.fold<int>(0, (sum, item) => sum + item.totalPoints);
  final normalized = scores
      .map(
        (item) => VedicGrahaDominance(
          grahaKey: item.grahaKey,
          house: item.house,
          rashi: item.rashi,
          totalPoints: item.totalPoints,
          dominantPercent:
              totalPoints == 0 ? 0 : (item.totalPoints / totalPoints) * 100,
          basePoints: item.basePoints,
          placementPoints: item.placementPoints,
          lordshipPoints: item.lordshipPoints,
          housePoints: item.housePoints,
          navamsaPoints: item.navamsaPoints,
          dignityPoints: item.dignityPoints,
          motionPoints: item.motionPoints,
          conditionPoints: item.conditionPoints,
          dashaPoints: item.dashaPoints,
          dignityTag: item.dignityTag,
          mahaDashaActive: item.mahaDashaActive,
          antarDashaActive: item.antarDashaActive,
        ),
      )
      .toList(growable: false)
    ..sort((left, right) => right.totalPoints.compareTo(left.totalPoints));

  final elementPoints = <String, double>{
    'Fire': 0,
    'Earth': 0,
    'Air': 0,
    'Water': 0,
  };
  final elementPlacements = <String, int>{
    'Fire': 0,
    'Earth': 0,
    'Air': 0,
    'Water': 0,
  };
  for (final score in normalized) {
    final element = rashiInsightFor(score.rashi).element;
    if (elementPoints.containsKey(element)) {
      final weightedPoints =
          score.totalPoints * _elementInfluenceMultiplier(score.grahaKey);
      elementPoints[element] = (elementPoints[element] ?? 0) + weightedPoints;
      elementPlacements[element] = (elementPlacements[element] ?? 0) + 1;
    }
  }
  final elementTotalPoints =
      elementPoints.values.fold<double>(0, (sum, item) => sum + item);
  final elementScores = elementPoints.entries
      .map(
        (entry) => VedicElementDominance(
          element: entry.key,
          points: entry.value,
          placements: elementPlacements[entry.key] ?? 0,
          percent: elementTotalPoints == 0
              ? 0
              : (entry.value / elementTotalPoints) * 100,
        ),
      )
      .toList(growable: false)
    ..sort((left, right) => right.points.compareTo(left.points));

  return VedicDominanceSnapshot(
    grahaScores: normalized,
    elementScores: elementScores,
    mahaDashaLordKey: mahaDashaLordKey,
    antarDashaLordKey: antarDashaLordKey,
  );
}

int _basePresencePoints(String grahaKey) {
  if (grahaKey == 'lagna') {
    return 20;
  }
  return 22;
}

int _housePlacementPoints(int house, String grahaKey) {
  var score = 0;
  if (_kendraHouses.contains(house)) {
    score += 5;
  }
  if (_trikonaHouses.contains(house)) {
    score += 4;
  }
  if (_upachayaHouses.contains(house)) {
    score += 2;
  }
  if (_dusthanaHouses.contains(house)) {
    score -= 4;
  }
  if (grahaKey == 'lagna' && house == 1) {
    score += 4;
  }
  return score;
}

Map<String, int> _computeHouseLordPointsFromLagna(String lagnaRashi) {
  final lagnaIndex = _rashiOrder.indexOf(lagnaRashi);
  if (lagnaIndex == -1) {
    return <String, int>{};
  }
  final scores = <String, int>{};
  for (var house = 1; house <= 12; house++) {
    final sign = _rashiOrder[(lagnaIndex + (house - 1)) % 12];
    final lord = _rashiLords[sign];
    if (lord == null) {
      continue;
    }
    scores[lord] = (scores[lord] ?? 0) + _houseLordshipPoints(house);
  }
  return scores;
}

int _houseLordshipPoints(int house) {
  switch (house) {
    case 1:
      return 6;
    case 5:
    case 9:
      return 5;
    case 4:
    case 7:
    case 10:
      return 4;
    case 2:
    case 11:
      return 2;
    case 3:
      return 1;
    case 6:
      return -2;
    case 8:
      return -4;
    case 12:
      return -3;
    default:
      return 0;
  }
}

enum _DignityStatus {
  exalted,
  mooltrikona,
  ownSign,
  friendlySign,
  neutral,
  inimicalSign,
  debilitated,
  lagna,
  node,
}

class _DignityAssessment {
  const _DignityAssessment({
    required this.status,
    required this.tag,
    required this.points,
  });

  final _DignityStatus status;
  final String tag;
  final int points;
}

_DignityAssessment _dignityAssessment(String grahaKey, String rashiRaw) {
  final rashi = _normalizeRashi(rashiRaw);
  if (grahaKey == 'lagna') {
    return const _DignityAssessment(
      status: _DignityStatus.lagna,
      tag: 'Ascendant',
      points: 0,
    );
  }
  if (grahaKey == 'rahu' || grahaKey == 'ketu') {
    return const _DignityAssessment(
      status: _DignityStatus.node,
      tag: 'Node',
      points: 0,
    );
  }
  if (_grahaExaltationSign[grahaKey] == rashi) {
    return const _DignityAssessment(
      status: _DignityStatus.exalted,
      tag: 'Exalted',
      points: 10,
    );
  }
  if (_grahaDebilitationSign[grahaKey] == rashi) {
    return const _DignityAssessment(
      status: _DignityStatus.debilitated,
      tag: 'Debilitated',
      points: -10,
    );
  }
  if (_grahaMooltrikonaSign[grahaKey] == rashi) {
    return const _DignityAssessment(
      status: _DignityStatus.mooltrikona,
      tag: 'Mooltrikona',
      points: 8,
    );
  }
  final ownSigns = _grahaOwnSigns[grahaKey];
  if (ownSigns != null && ownSigns.contains(rashi)) {
    return const _DignityAssessment(
      status: _DignityStatus.ownSign,
      tag: 'Own Sign',
      points: 7,
    );
  }

  final signLord = _rashiLords[rashi];
  final relation = _naturalRelationship(grahaKey, signLord);
  switch (relation) {
    case _Relationship.friend:
      return const _DignityAssessment(
        status: _DignityStatus.friendlySign,
        tag: 'Friendly Sign',
        points: 4,
      );
    case _Relationship.enemy:
      return const _DignityAssessment(
        status: _DignityStatus.inimicalSign,
        tag: 'Inimical Sign',
        points: -4,
      );
    case _Relationship.neutral:
      return const _DignityAssessment(
        status: _DignityStatus.neutral,
        tag: 'Neutral',
        points: 1,
      );
  }
}

int _navamsaDignityPoints(_DignityStatus status) {
  switch (status) {
    case _DignityStatus.exalted:
      return 4;
    case _DignityStatus.mooltrikona:
      return 3;
    case _DignityStatus.ownSign:
      return 3;
    case _DignityStatus.friendlySign:
      return 2;
    case _DignityStatus.inimicalSign:
      return -2;
    case _DignityStatus.debilitated:
      return -4;
    case _DignityStatus.neutral:
    case _DignityStatus.lagna:
    case _DignityStatus.node:
      return 0;
  }
}

enum _Relationship {
  friend,
  neutral,
  enemy,
}

_Relationship _naturalRelationship(String grahaKey, String? signLordKey) {
  if (signLordKey == null) {
    return _Relationship.neutral;
  }
  if (grahaKey == signLordKey) {
    return _Relationship.friend;
  }
  final friends = _grahaFriends[grahaKey];
  if (friends != null && friends.contains(signLordKey)) {
    return _Relationship.friend;
  }
  final enemies = _grahaEnemies[grahaKey];
  if (enemies != null && enemies.contains(signLordKey)) {
    return _Relationship.enemy;
  }
  final neutrals = _grahaNeutrals[grahaKey];
  if (neutrals != null && neutrals.contains(signLordKey)) {
    return _Relationship.neutral;
  }
  return _Relationship.neutral;
}

int _motionPoints(bool retrograde, String grahaKey) {
  if (!retrograde || grahaKey == 'lagna') {
    return 0;
  }
  switch (grahaKey) {
    case 'shani':
    case 'guru':
    case 'mangal':
      return 3;
    case 'budha':
    case 'shukra':
      return 2;
    default:
      return 0;
  }
}

int _conditionPoints(bool combust, String grahaKey) {
  if (!combust || grahaKey == 'lagna') {
    return 0;
  }
  switch (grahaKey) {
    case 'budha':
      return -2;
    case 'shukra':
      return -3;
    case 'mangal':
    case 'guru':
    case 'shani':
      return -4;
    default:
      return 0;
  }
}

int _dashaBoost({
  required String grahaKey,
  required String? mahaDashaLordKey,
  required String? antarDashaLordKey,
}) {
  var score = 0;
  if (grahaKey == mahaDashaLordKey) {
    score += 10;
  }
  if (grahaKey == antarDashaLordKey) {
    score += 6;
  }
  return score;
}

int _clampMinimum(int value, int minimum) => value < minimum ? minimum : value;

double _elementInfluenceMultiplier(String grahaKey) {
  switch (grahaKey) {
    case 'lagna':
      return 1.25;
    case 'moon':
      return 1.15;
    case 'sun':
      return 1.10;
    case 'rahu':
    case 'ketu':
      return 0.90;
    default:
      return 1.00;
  }
}

String? _resolveMahaDashaLordKey(DashaSummary dasha) {
  for (final period in dasha.mahaTimeline) {
    if (period.active) {
      final byKey = _supportedGrahaKey(period.lordKey);
      if (byKey != null) {
        return byKey;
      }
      final byLordName = _dashaLordAlias[_normalizeLord(period.lord)];
      if (byLordName != null) {
        return byLordName;
      }
    }
  }
  return _dashaLordAlias[_normalizeLord(dasha.currentMahaDasha)];
}

String? _resolveAntarDashaLordKey(DashaSummary dasha) {
  for (final period in dasha.antarTimelineCurrentMaha) {
    if (period.active) {
      final byKey = _supportedGrahaKey(period.lordKey);
      if (byKey != null) {
        return byKey;
      }
      final byLordName = _dashaLordAlias[_normalizeLord(period.lord)];
      if (byLordName != null) {
        return byLordName;
      }
    }
  }
  return _dashaLordAlias[_normalizeLord(dasha.currentAntarDasha)];
}

String? _supportedGrahaKey(String raw) {
  if (_dominanceGrahaKeys.contains(raw)) {
    return raw;
  }
  return null;
}

String _normalizeLord(String raw) {
  return raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
}

String _normalizeRashi(String rashiRaw) {
  final canonical = _rashiAliases[rashiRaw.trim()] ?? rashiRaw.trim();
  return canonical;
}
