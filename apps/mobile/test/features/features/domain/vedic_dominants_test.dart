import 'package:flutter_test/flutter_test.dart';
import 'package:trikaal_mobile/features/charts/data/models/compute_report_models.dart';
import 'package:trikaal_mobile/features/dasha/data/models/dasha_models.dart';
import 'package:trikaal_mobile/features/features/domain/vedic_dominants.dart';

void main() {
  group('computeVedicDominanceSnapshot', () {
    test('applies dasha weighting to active maha and antar lords', () {
      final snapshot = computeVedicDominanceSnapshot(
        grahaTable: _sampleGrahaTable(),
        dasha: _dashaSummary(
          mahaLordKey: 'moon',
          antarLordKey: 'sun',
        ),
      );

      final moonScore = snapshot.grahaScores.firstWhere(
        (item) => item.grahaKey == 'moon',
      );
      final sunScore = snapshot.grahaScores.firstWhere(
        (item) => item.grahaKey == 'sun',
      );
      final lagnaScore = snapshot.grahaScores.firstWhere(
        (item) => item.grahaKey == 'lagna',
      );

      expect(moonScore.mahaDashaActive, isTrue);
      expect(sunScore.antarDashaActive, isTrue);
      expect(moonScore.dashaPoints, equals(10));
      expect(sunScore.dashaPoints, equals(6));
      expect(moonScore.totalPoints, greaterThan(lagnaScore.totalPoints));
      expect(sunScore.totalPoints, greaterThan(lagnaScore.totalPoints));
    });

    test('applies dignity tags and scores', () {
      final snapshot = computeVedicDominanceSnapshot(
        grahaTable: _sampleGrahaTable(
          sunRashi: 'Mesh', // exalted
          shaniRashi: 'Mesh', // debilitated
          budhaRashi: 'Kany', // own + exalted path chooses exalted
        ),
        dasha: _dashaSummary(
          mahaLordKey: 'guru',
          antarLordKey: 'shani',
        ),
      );

      final sun =
          snapshot.grahaScores.firstWhere((item) => item.grahaKey == 'sun');
      final shani =
          snapshot.grahaScores.firstWhere((item) => item.grahaKey == 'shani');
      final budha =
          snapshot.grahaScores.firstWhere((item) => item.grahaKey == 'budha');

      expect(sun.dignityTag, equals('Exalted'));
      expect(shani.dignityTag, equals('Debilitated'));
      expect(budha.dignityTag, equals('Exalted'));
      expect(sun.dignityPoints, greaterThan(0));
      expect(shani.dignityPoints, lessThan(0));
    });

    test('computes weighted element percentages from graha dominance points',
        () {
      final snapshot = computeVedicDominanceSnapshot(
        grahaTable: _sampleGrahaTable(
          sunRashi: 'Kark',
          moonRashi: 'Kark',
          lagnaRashi: 'Kark',
        ),
        dasha: _dashaSummary(
          mahaLordKey: 'sun',
          antarLordKey: 'moon',
        ),
      );

      final water = snapshot.elementScores.firstWhere(
        (entry) => entry.element == 'Water',
      );
      final totalPercent = snapshot.elementScores.fold<double>(
        0,
        (sum, item) => sum + item.percent,
      );

      expect(totalPercent, closeTo(100, 0.01));
      expect(water.placements, greaterThanOrEqualTo(3));
      expect(water.points, greaterThan(0));
      expect(water.percent, greaterThan(20));
    });

    test('updates element balance when dasha-lord emphasis changes', () {
      final baseTable = _sampleGrahaTable(
        sunRashi: 'Mesh',
        moonRashi: 'Kark',
        lagnaRashi: 'Vrish',
      );
      final sunDriven = computeVedicDominanceSnapshot(
        grahaTable: baseTable,
        dasha: _dashaSummary(
          mahaLordKey: 'sun',
          antarLordKey: 'sun',
        ),
      );
      final moonDriven = computeVedicDominanceSnapshot(
        grahaTable: baseTable,
        dasha: _dashaSummary(
          mahaLordKey: 'moon',
          antarLordKey: 'moon',
        ),
      );

      final fireSunDriven = sunDriven.elementScores.firstWhere(
        (entry) => entry.element == 'Fire',
      );
      final fireMoonDriven = moonDriven.elementScores.firstWhere(
        (entry) => entry.element == 'Fire',
      );

      expect(fireSunDriven.percent, greaterThan(fireMoonDriven.percent));
    });
  });
}

ReportGrahaTable _sampleGrahaTable({
  String sunRashi = 'Simh',
  String moonRashi = 'Kark',
  String budhaRashi = 'Mitu',
  String shaniRashi = 'Makar',
  String lagnaRashi = 'Tula',
}) {
  return ReportGrahaTable(
    sun: _entry(
      key: 'sun',
      rashi: sunRashi,
      house: 10,
      combust: false,
    ),
    moon: _entry(
      key: 'moon',
      rashi: moonRashi,
      house: 4,
      combust: false,
    ),
    mangal: _entry(
      key: 'mangal',
      rashi: 'Vrsc',
      house: 1,
      combust: false,
    ),
    budha: _entry(
      key: 'budha',
      rashi: budhaRashi,
      house: 11,
      combust: true,
    ),
    guru: _entry(
      key: 'guru',
      rashi: 'Dhanu',
      house: 9,
      combust: false,
    ),
    shukra: _entry(
      key: 'shukra',
      rashi: 'Tula',
      house: 12,
      combust: false,
    ),
    shani: _entry(
      key: 'shani',
      rashi: shaniRashi,
      house: 8,
      retrograde: true,
      combust: false,
    ),
    rahu: _entry(
      key: 'rahu',
      rashi: 'Kumb',
      house: 5,
      retrograde: true,
      combust: false,
    ),
    ketu: _entry(
      key: 'ketu',
      rashi: 'Simh',
      house: 11,
      retrograde: true,
      combust: false,
    ),
    spashthRahu: _entry(
      key: 'spashth_rahu',
      rashi: 'Kumb',
      house: 5,
      retrograde: true,
      combust: false,
    ),
    spashthKetu: _entry(
      key: 'spashth_ketu',
      rashi: 'Simh',
      house: 11,
      retrograde: true,
      combust: false,
    ),
    lagna: _entry(
      key: 'lagna',
      rashi: lagnaRashi,
      house: 1,
      combust: false,
    ),
  );
}

DashaSummary _dashaSummary({
  required String mahaLordKey,
  required String antarLordKey,
}) {
  return DashaSummary(
    system: 'Vimshottari',
    asOfIso: '2026-04-03T00:00:00+00:00',
    birthMoonNakshatra: 'Hasta',
    currentMahaDasha: mahaLordKey,
    currentAntarDasha: antarLordKey,
    activeFrom: '2026-01-01T00:00:00+00:00',
    activeUntil: '2026-12-31T00:00:00+00:00',
    currentMahaStart: '2026-01-01T00:00:00+00:00',
    currentMahaEnd: '2032-01-01T00:00:00+00:00',
    mahaTimeline: <DashaPeriod>[
      DashaPeriod(
        lord: mahaLordKey,
        lordKey: mahaLordKey,
        start: '2026-01-01T00:00:00+00:00',
        end: '2032-01-01T00:00:00+00:00',
        active: true,
      ),
    ],
    antarTimelineCurrentMaha: <DashaPeriod>[
      DashaPeriod(
        lord: antarLordKey,
        lordKey: antarLordKey,
        start: '2026-01-01T00:00:00+00:00',
        end: '2026-12-31T00:00:00+00:00',
        active: true,
      ),
    ],
  );
}

ReportGrahaEntry _entry({
  required String key,
  required String rashi,
  required int house,
  required bool combust,
  bool retrograde = false,
}) {
  return ReportGrahaEntry(
    key: key,
    siderealDeg: 10,
    siderealDegRaw: 10,
    speedDegPerDay: 1,
    rashi: rashi,
    nakshatra: 'Hasta',
    pada: 1,
    house: house,
    d9Rashi: rashi,
    d9House: house,
    retrograde: retrograde,
    combust: combust,
  );
}
