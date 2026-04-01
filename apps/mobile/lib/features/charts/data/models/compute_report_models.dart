import '../../../dasha/data/models/dasha_models.dart';
import 'compute_chart_models.dart';

class ComputeReportResponse {
  const ComputeReportResponse({
    required this.profile,
    required this.normalizedInput,
    required this.resolvedPlace,
    required this.snapshot,
    required this.dasha,
    required this.interpretations,
    required this.dailyTransit,
  });

  final ReportProfile profile;
  final ReportNormalizedInput normalizedInput;
  final ResolvedPlace resolvedPlace;
  final ReportSnapshot snapshot;
  final DashaSummary dasha;
  final ReportInterpretations interpretations;
  final ReportDailyTransitBrief dailyTransit;

  factory ComputeReportResponse.fromJson(Map<String, dynamic> json) {
    return ComputeReportResponse(
      profile: ReportProfile.fromJson(_readMap(json, 'profile')),
      normalizedInput: ReportNormalizedInput.fromJson(
        _readMap(json, 'normalized_input'),
      ),
      resolvedPlace: ResolvedPlace.fromJson(_readMap(json, 'resolved_place')),
      snapshot: ReportSnapshot.fromJson(_readMap(json, 'snapshot')),
      dasha: DashaSummary.fromJson(_readMap(json, 'dasha')),
      interpretations: ReportInterpretations.fromJson(
        _readMap(json, 'interpretations'),
      ),
      dailyTransit: ReportDailyTransitBrief.fromJson(
        _readMap(json, 'daily_transit'),
      ),
    );
  }
}

class ReportDailyTransitBrief {
  const ReportDailyTransitBrief({
    required this.version,
    required this.asOfLocalIso,
    required this.timezone,
    required this.cards,
  });

  final String version;
  final String asOfLocalIso;
  final String timezone;
  final List<ReportDailyTransitCard> cards;

  factory ReportDailyTransitBrief.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'];
    if (cardsRaw is! List) {
      throw const FormatException('Field "daily_transit.cards" must be a list');
    }
    return ReportDailyTransitBrief(
      version: _readString(json, 'version'),
      asOfLocalIso: _readString(json, 'as_of_local_iso'),
      timezone: _readString(json, 'timezone'),
      cards: cardsRaw
          .map(
            (Object? raw) => ReportDailyTransitCard.fromJson(
              _asMap(raw, 'daily_transit.cards[]'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ReportDailyTransitCard {
  const ReportDailyTransitCard({
    required this.cardId,
    required this.transitGrahaKey,
    required this.transitHouseFromLagna,
    required this.transitRashi,
    required this.focusTag,
    required this.title,
    required this.summary,
    required this.doItems,
    required this.watchItems,
  });

  final String cardId;
  final String transitGrahaKey;
  final int transitHouseFromLagna;
  final String transitRashi;
  final String focusTag;
  final ReportLocalizedText title;
  final ReportLocalizedText summary;
  final List<ReportLocalizedText> doItems;
  final List<ReportLocalizedText> watchItems;

  factory ReportDailyTransitCard.fromJson(Map<String, dynamic> json) {
    final doItemsRaw = json['do_items'];
    if (doItemsRaw is! List) {
      throw const FormatException('Field "do_items" must be a list');
    }
    final watchItemsRaw = json['watch_items'];
    if (watchItemsRaw is! List) {
      throw const FormatException('Field "watch_items" must be a list');
    }
    return ReportDailyTransitCard(
      cardId: _readString(json, 'card_id'),
      transitGrahaKey: _readString(json, 'transit_graha_key'),
      transitHouseFromLagna: _readInt(json, 'transit_house_from_lagna'),
      transitRashi: _readString(json, 'transit_rashi'),
      focusTag: _readString(json, 'focus_tag'),
      title: ReportLocalizedText.fromJson(_readMap(json, 'title')),
      summary: ReportLocalizedText.fromJson(_readMap(json, 'summary')),
      doItems: doItemsRaw
          .map(
            (Object? raw) => ReportLocalizedText.fromJson(
              _asMap(raw, 'daily_transit.cards[].do_items[]'),
            ),
          )
          .toList(growable: false),
      watchItems: watchItemsRaw
          .map(
            (Object? raw) => ReportLocalizedText.fromJson(
              _asMap(raw, 'daily_transit.cards[].watch_items[]'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ReportInterpretations {
  const ReportInterpretations({
    required this.version,
    required this.cards,
  });

  final String version;
  final List<ReportInterpretationCard> cards;

  factory ReportInterpretations.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'];
    if (cardsRaw is! List) {
      throw const FormatException('Field "cards" must be a list');
    }
    return ReportInterpretations(
      version: _readString(json, 'version'),
      cards: cardsRaw
          .map(
            (Object? raw) => ReportInterpretationCard.fromJson(
              _asMap(raw, 'interpretations.cards[]'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ReportInterpretationCard {
  const ReportInterpretationCard({
    required this.cardId,
    required this.category,
    required this.confidence,
    required this.strengthScore,
    required this.title,
    required this.summary,
    required this.impact,
    required this.evidence,
  });

  final String cardId;
  final String category;
  final String confidence;
  final double strengthScore;
  final ReportLocalizedText title;
  final ReportLocalizedText summary;
  final ReportLocalizedText impact;
  final List<ReportLocalizedText> evidence;

  factory ReportInterpretationCard.fromJson(Map<String, dynamic> json) {
    final evidenceRaw = json['evidence'];
    if (evidenceRaw is! List) {
      throw const FormatException('Field "evidence" must be a list');
    }
    return ReportInterpretationCard(
      cardId: _readString(json, 'card_id'),
      category: _readString(json, 'category'),
      confidence: _readString(json, 'confidence'),
      strengthScore: _readDouble(json, 'strength_score'),
      title: ReportLocalizedText.fromJson(_readMap(json, 'title')),
      summary: ReportLocalizedText.fromJson(_readMap(json, 'summary')),
      impact: ReportLocalizedText.fromJson(_readMap(json, 'impact')),
      evidence: evidenceRaw
          .map(
            (Object? raw) => ReportLocalizedText.fromJson(
              _asMap(raw, 'interpretations.cards[].evidence[]'),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ReportLocalizedText {
  const ReportLocalizedText({
    required this.english,
    required this.vedic,
  });

  final String english;
  final String vedic;

  factory ReportLocalizedText.fromJson(Map<String, dynamic> json) {
    return ReportLocalizedText(
      english: _readString(json, 'english'),
      vedic: _readString(json, 'vedic'),
    );
  }
}

class ReportProfile {
  const ReportProfile({
    required this.profileId,
    required this.zodiacSystem,
    required this.ayanamsha,
    required this.calculationMethod,
  });

  final String profileId;
  final String zodiacSystem;
  final String ayanamsha;
  final String calculationMethod;

  factory ReportProfile.fromJson(Map<String, dynamic> json) {
    return ReportProfile(
      profileId: _readString(json, 'profile_id'),
      zodiacSystem: _readString(json, 'zodiac_system'),
      ayanamsha: _readString(json, 'ayanamsha'),
      calculationMethod: _readString(json, 'calculation_method'),
    );
  }
}

class ReportNormalizedInput {
  const ReportNormalizedInput({
    required this.localDate,
    required this.localTime,
    required this.placeQuery,
  });

  final String localDate;
  final String localTime;
  final String placeQuery;

  factory ReportNormalizedInput.fromJson(Map<String, dynamic> json) {
    return ReportNormalizedInput(
      localDate: _readString(json, 'local_date'),
      localTime: _readString(json, 'local_time'),
      placeQuery: _readString(json, 'place_query'),
    );
  }
}

class ReportSnapshot {
  const ReportSnapshot({
    required this.meta,
    required this.panchanga,
    required this.astronomy,
    required this.vedic,
    required this.bhava,
    required this.varga,
    required this.grahaTable,
  });

  final ReportSnapshotMeta meta;
  final ReportPanchanga panchanga;
  final ReportAstronomy astronomy;
  final ReportVedic vedic;
  final ReportBhava bhava;
  final ReportVarga varga;
  final ReportGrahaTable grahaTable;

  factory ReportSnapshot.fromJson(Map<String, dynamic> json) {
    return ReportSnapshot(
      meta: ReportSnapshotMeta.fromJson(_readMap(json, 'meta')),
      panchanga: ReportPanchanga.fromJson(_readMap(json, 'panchanga')),
      astronomy: ReportAstronomy.fromJson(_readMap(json, 'astronomy')),
      vedic: ReportVedic.fromJson(_readMap(json, 'vedic')),
      bhava: ReportBhava.fromJson(_readMap(json, 'bhava')),
      varga: ReportVarga.fromJson(_readMap(json, 'varga')),
      grahaTable: ReportGrahaTable.fromJson(_readMap(json, 'graha_table')),
    );
  }
}

class ReportSnapshotMeta {
  const ReportSnapshotMeta({
    required this.status,
    required this.profileId,
    required this.timezone,
    required this.utcIso,
  });

  final String status;
  final String profileId;
  final String timezone;
  final String utcIso;

  factory ReportSnapshotMeta.fromJson(Map<String, dynamic> json) {
    return ReportSnapshotMeta(
      status: _readString(json, 'status'),
      profileId: _readString(json, 'profile_id'),
      timezone: _readString(json, 'timezone'),
      utcIso: _readString(json, 'utc_iso'),
    );
  }
}

class ReportPanchanga {
  const ReportPanchanga({
    required this.vara,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.sunrise,
    required this.sunset,
  });

  final ReportVara vara;
  final ReportTithi tithi;
  final ReportNakshatra nakshatra;
  final ReportYoga yoga;
  final ReportKarana karana;
  final ReportSolarEvent sunrise;
  final ReportSolarEvent sunset;

  factory ReportPanchanga.fromJson(Map<String, dynamic> json) {
    return ReportPanchanga(
      vara: ReportVara.fromJson(_readMap(json, 'vara')),
      tithi: ReportTithi.fromJson(_readMap(json, 'tithi')),
      nakshatra: ReportNakshatra.fromJson(_readMap(json, 'nakshatra')),
      yoga: ReportYoga.fromJson(_readMap(json, 'yoga')),
      karana: ReportKarana.fromJson(_readMap(json, 'karana')),
      sunrise: ReportSolarEvent.fromJson(_readMap(json, 'sunrise')),
      sunset: ReportSolarEvent.fromJson(_readMap(json, 'sunset')),
    );
  }
}

class ReportVara {
  const ReportVara({
    required this.number,
    required this.nameVedic,
    required this.nameEnglish,
  });

  final int number;
  final String nameVedic;
  final String nameEnglish;

  factory ReportVara.fromJson(Map<String, dynamic> json) {
    return ReportVara(
      number: _readInt(json, 'number'),
      nameVedic: _readString(json, 'name_vedic'),
      nameEnglish: _readString(json, 'name_english'),
    );
  }
}

class ReportTithi {
  const ReportTithi({
    required this.number,
    required this.paksha,
    required this.pakshaEnglish,
    required this.nameVedic,
    required this.nameEnglish,
    required this.progressPercent,
  });

  final int number;
  final String paksha;
  final String pakshaEnglish;
  final String nameVedic;
  final String nameEnglish;
  final double progressPercent;

  factory ReportTithi.fromJson(Map<String, dynamic> json) {
    return ReportTithi(
      number: _readInt(json, 'number'),
      paksha: _readString(json, 'paksha'),
      pakshaEnglish: _readString(json, 'paksha_english'),
      nameVedic: _readString(json, 'name_vedic'),
      nameEnglish: _readString(json, 'name_english'),
      progressPercent: _readDouble(json, 'progress_percent'),
    );
  }
}

class ReportNakshatra {
  const ReportNakshatra({
    required this.number,
    required this.nameVedic,
    required this.nameEnglish,
    required this.pada,
    required this.progressPercent,
  });

  final int number;
  final String nameVedic;
  final String nameEnglish;
  final int pada;
  final double progressPercent;

  factory ReportNakshatra.fromJson(Map<String, dynamic> json) {
    return ReportNakshatra(
      number: _readInt(json, 'number'),
      nameVedic: _readString(json, 'name_vedic'),
      nameEnglish: _readString(json, 'name_english'),
      pada: _readInt(json, 'pada'),
      progressPercent: _readDouble(json, 'progress_percent'),
    );
  }
}

class ReportYoga {
  const ReportYoga({
    required this.number,
    required this.nameVedic,
    required this.nameEnglish,
    required this.progressPercent,
  });

  final int number;
  final String nameVedic;
  final String nameEnglish;
  final double progressPercent;

  factory ReportYoga.fromJson(Map<String, dynamic> json) {
    return ReportYoga(
      number: _readInt(json, 'number'),
      nameVedic: _readString(json, 'name_vedic'),
      nameEnglish: _readString(json, 'name_english'),
      progressPercent: _readDouble(json, 'progress_percent'),
    );
  }
}

class ReportKarana {
  const ReportKarana({
    required this.serial,
    required this.nameVedic,
    required this.nameEnglish,
    required this.progressPercent,
  });

  final int serial;
  final String nameVedic;
  final String nameEnglish;
  final double progressPercent;

  factory ReportKarana.fromJson(Map<String, dynamic> json) {
    return ReportKarana(
      serial: _readInt(json, 'serial'),
      nameVedic: _readString(json, 'name_vedic'),
      nameEnglish: _readString(json, 'name_english'),
      progressPercent: _readDouble(json, 'progress_percent'),
    );
  }
}

class ReportSolarEvent {
  const ReportSolarEvent({
    required this.utcIso,
    required this.localIso,
    required this.localTime,
  });

  final String utcIso;
  final String localIso;
  final String localTime;

  factory ReportSolarEvent.fromJson(Map<String, dynamic> json) {
    return ReportSolarEvent(
      utcIso: _readString(json, 'utc_iso'),
      localIso: _readString(json, 'local_iso'),
      localTime: _readString(json, 'local_time'),
    );
  }
}

class ReportAstronomy {
  const ReportAstronomy({
    required this.julianDayUtc,
    required this.referenceDisplayOffsetDeg,
    required this.referenceLagnaDisplayOffsetDeg,
    required this.sunSiderealDeg,
    required this.sunSiderealDegRaw,
    required this.moonSiderealDeg,
    required this.moonSiderealDegRaw,
    required this.mangalSiderealDeg,
    required this.mangalSiderealDegRaw,
    required this.budhaSiderealDeg,
    required this.budhaSiderealDegRaw,
    required this.guruSiderealDeg,
    required this.guruSiderealDegRaw,
    required this.shukraSiderealDeg,
    required this.shukraSiderealDegRaw,
    required this.shaniSiderealDeg,
    required this.shaniSiderealDegRaw,
    required this.rahuSiderealDeg,
    required this.rahuSiderealDegRaw,
    required this.ketuSiderealDeg,
    required this.ketuSiderealDegRaw,
    required this.spashthRahuSiderealDeg,
    required this.spashthRahuSiderealDegRaw,
    required this.spashthKetuSiderealDeg,
    required this.spashthKetuSiderealDegRaw,
    required this.lagnaSiderealDeg,
    required this.lagnaSiderealDegRaw,
  });

  final double julianDayUtc;
  final double referenceDisplayOffsetDeg;
  final double referenceLagnaDisplayOffsetDeg;
  final double sunSiderealDeg;
  final double sunSiderealDegRaw;
  final double moonSiderealDeg;
  final double moonSiderealDegRaw;
  final double mangalSiderealDeg;
  final double mangalSiderealDegRaw;
  final double budhaSiderealDeg;
  final double budhaSiderealDegRaw;
  final double guruSiderealDeg;
  final double guruSiderealDegRaw;
  final double shukraSiderealDeg;
  final double shukraSiderealDegRaw;
  final double shaniSiderealDeg;
  final double shaniSiderealDegRaw;
  final double rahuSiderealDeg;
  final double rahuSiderealDegRaw;
  final double ketuSiderealDeg;
  final double ketuSiderealDegRaw;
  final double spashthRahuSiderealDeg;
  final double spashthRahuSiderealDegRaw;
  final double spashthKetuSiderealDeg;
  final double spashthKetuSiderealDegRaw;
  final double lagnaSiderealDeg;
  final double lagnaSiderealDegRaw;

  factory ReportAstronomy.fromJson(Map<String, dynamic> json) {
    return ReportAstronomy(
      julianDayUtc: _readDouble(json, 'julian_day_utc'),
      referenceDisplayOffsetDeg: _readDouble(json, 'reference_display_offset_deg'),
      referenceLagnaDisplayOffsetDeg:
          _readDouble(json, 'reference_lagna_display_offset_deg'),
      sunSiderealDeg: _readDouble(json, 'sun_sidereal_deg'),
      sunSiderealDegRaw: _readDouble(json, 'sun_sidereal_deg_raw'),
      moonSiderealDeg: _readDouble(json, 'moon_sidereal_deg'),
      moonSiderealDegRaw: _readDouble(json, 'moon_sidereal_deg_raw'),
      mangalSiderealDeg: _readDouble(json, 'mangal_sidereal_deg'),
      mangalSiderealDegRaw: _readDouble(json, 'mangal_sidereal_deg_raw'),
      budhaSiderealDeg: _readDouble(json, 'budha_sidereal_deg'),
      budhaSiderealDegRaw: _readDouble(json, 'budha_sidereal_deg_raw'),
      guruSiderealDeg: _readDouble(json, 'guru_sidereal_deg'),
      guruSiderealDegRaw: _readDouble(json, 'guru_sidereal_deg_raw'),
      shukraSiderealDeg: _readDouble(json, 'shukra_sidereal_deg'),
      shukraSiderealDegRaw: _readDouble(json, 'shukra_sidereal_deg_raw'),
      shaniSiderealDeg: _readDouble(json, 'shani_sidereal_deg'),
      shaniSiderealDegRaw: _readDouble(json, 'shani_sidereal_deg_raw'),
      rahuSiderealDeg: _readDouble(json, 'rahu_sidereal_deg'),
      rahuSiderealDegRaw: _readDouble(json, 'rahu_sidereal_deg_raw'),
      ketuSiderealDeg: _readDouble(json, 'ketu_sidereal_deg'),
      ketuSiderealDegRaw: _readDouble(json, 'ketu_sidereal_deg_raw'),
      spashthRahuSiderealDeg: _readDouble(json, 'spashth_rahu_sidereal_deg'),
      spashthRahuSiderealDegRaw:
          _readDouble(json, 'spashth_rahu_sidereal_deg_raw'),
      spashthKetuSiderealDeg: _readDouble(json, 'spashth_ketu_sidereal_deg'),
      spashthKetuSiderealDegRaw:
          _readDouble(json, 'spashth_ketu_sidereal_deg_raw'),
      lagnaSiderealDeg: _readDouble(json, 'lagna_sidereal_deg'),
      lagnaSiderealDegRaw: _readDouble(json, 'lagna_sidereal_deg_raw'),
    );
  }
}

class ReportVedicGraha {
  const ReportVedicGraha({
    required this.rashi,
    required this.nakshatra,
    required this.pada,
  });

  final String rashi;
  final String nakshatra;
  final int pada;
}

class ReportVedic {
  const ReportVedic({
    required this.sun,
    required this.moon,
    required this.lagna,
    required this.mangal,
    required this.budha,
    required this.guru,
    required this.shukra,
    required this.shani,
    required this.rahu,
    required this.ketu,
    required this.spashthRahu,
    required this.spashthKetu,
  });

  final ReportVedicGraha sun;
  final ReportVedicGraha moon;
  final ReportVedicGraha lagna;
  final ReportVedicGraha mangal;
  final ReportVedicGraha budha;
  final ReportVedicGraha guru;
  final ReportVedicGraha shukra;
  final ReportVedicGraha shani;
  final ReportVedicGraha rahu;
  final ReportVedicGraha ketu;
  final ReportVedicGraha spashthRahu;
  final ReportVedicGraha spashthKetu;

  factory ReportVedic.fromJson(Map<String, dynamic> json) {
    return ReportVedic(
      sun: _readVedicGraha(json, 'sun'),
      moon: _readVedicGraha(json, 'moon'),
      lagna: _readVedicGraha(json, 'lagna'),
      mangal: _readVedicGraha(json, 'mangal'),
      budha: _readVedicGraha(json, 'budha'),
      guru: _readVedicGraha(json, 'guru'),
      shukra: _readVedicGraha(json, 'shukra'),
      shani: _readVedicGraha(json, 'shani'),
      rahu: _readVedicGraha(json, 'rahu'),
      ketu: _readVedicGraha(json, 'ketu'),
      spashthRahu: _readVedicGraha(json, 'spashth_rahu'),
      spashthKetu: _readVedicGraha(json, 'spashth_ketu'),
    );
  }
}

class ReportBhava {
  const ReportBhava({
    required this.lagnaHouse,
    required this.sunHouse,
    required this.moonHouse,
    required this.mangalHouse,
    required this.budhaHouse,
    required this.guruHouse,
    required this.shukraHouse,
    required this.shaniHouse,
    required this.rahuHouse,
    required this.ketuHouse,
    required this.spashthRahuHouse,
    required this.spashthKetuHouse,
  });

  final int lagnaHouse;
  final int sunHouse;
  final int moonHouse;
  final int mangalHouse;
  final int budhaHouse;
  final int guruHouse;
  final int shukraHouse;
  final int shaniHouse;
  final int rahuHouse;
  final int ketuHouse;
  final int spashthRahuHouse;
  final int spashthKetuHouse;

  factory ReportBhava.fromJson(Map<String, dynamic> json) {
    return ReportBhava(
      lagnaHouse: _readInt(json, 'lagna_house'),
      sunHouse: _readInt(json, 'sun_house'),
      moonHouse: _readInt(json, 'moon_house'),
      mangalHouse: _readInt(json, 'mangal_house'),
      budhaHouse: _readInt(json, 'budha_house'),
      guruHouse: _readInt(json, 'guru_house'),
      shukraHouse: _readInt(json, 'shukra_house'),
      shaniHouse: _readInt(json, 'shani_house'),
      rahuHouse: _readInt(json, 'rahu_house'),
      ketuHouse: _readInt(json, 'ketu_house'),
      spashthRahuHouse: _readInt(json, 'spashth_rahu_house'),
      spashthKetuHouse: _readInt(json, 'spashth_ketu_house'),
    );
  }
}

class ReportVarga {
  const ReportVarga({
    required this.d1,
    required this.d9,
  });

  final ReportDivision d1;
  final ReportDivision d9;

  factory ReportVarga.fromJson(Map<String, dynamic> json) {
    return ReportVarga(
      d1: ReportDivision.fromJson(_readMap(json, 'd1')),
      d9: ReportDivision.fromJson(_readMap(json, 'd9')),
    );
  }
}

class ReportDivision {
  const ReportDivision({
    required this.lagnaRashi,
    required this.houses,
  });

  final String lagnaRashi;
  final Map<int, ReportHouse> houses;

  List<MapEntry<int, ReportHouse>> get sortedHouses {
    final entries = houses.entries.toList(growable: false);
    entries.sort(
      (MapEntry<int, ReportHouse> left, MapEntry<int, ReportHouse> right) =>
          left.key.compareTo(right.key),
    );
    return entries;
  }

  factory ReportDivision.fromJson(Map<String, dynamic> json) {
    final rawHouses = _readMap(json, 'houses');
    final houses = <int, ReportHouse>{};
    for (final MapEntry<String, dynamic> entry in rawHouses.entries) {
      final houseIndex = int.tryParse(entry.key);
      if (houseIndex == null) {
        throw FormatException(
          'Invalid house index "${entry.key}" in division houses',
        );
      }
      houses[houseIndex] = ReportHouse.fromJson(
        _asMap(entry.value, 'division.houses.${entry.key}'),
      );
    }
    final expectedKeys = <int>{for (int i = 1; i <= 12; i++) i};
    if (houses.keys.toSet().length != 12 ||
        !houses.keys.toSet().containsAll(expectedKeys)) {
      throw const FormatException('Division houses must contain keys 1..12');
    }

    return ReportDivision(
      lagnaRashi: _readString(json, 'lagna_rashi'),
      houses: houses,
    );
  }
}

class ReportHouse {
  const ReportHouse({
    required this.rashi,
    required this.occupants,
  });

  final String rashi;
  final List<String> occupants;

  factory ReportHouse.fromJson(Map<String, dynamic> json) {
    return ReportHouse(
      rashi: _readString(json, 'rashi'),
      occupants: _readStringList(json, 'occupants'),
    );
  }
}

class ReportGrahaEntry {
  const ReportGrahaEntry({
    required this.key,
    required this.siderealDeg,
    required this.siderealDegRaw,
    required this.speedDegPerDay,
    required this.rashi,
    required this.nakshatra,
    required this.pada,
    required this.house,
    required this.d9Rashi,
    required this.d9House,
    required this.retrograde,
    required this.combust,
  });

  final String key;
  final double siderealDeg;
  final double siderealDegRaw;
  final double speedDegPerDay;
  final String rashi;
  final String nakshatra;
  final int pada;
  final int house;
  final String d9Rashi;
  final int d9House;
  final bool retrograde;
  final bool combust;

  factory ReportGrahaEntry.fromJson(Map<String, dynamic> json) {
    return ReportGrahaEntry(
      key: _readString(json, 'key'),
      siderealDeg: _readDouble(json, 'sidereal_deg'),
      siderealDegRaw: _readDouble(json, 'sidereal_deg_raw'),
      speedDegPerDay: _readDouble(json, 'speed_deg_per_day'),
      rashi: _readString(json, 'rashi'),
      nakshatra: _readString(json, 'nakshatra'),
      pada: _readInt(json, 'pada'),
      house: _readInt(json, 'house'),
      d9Rashi: _readString(json, 'd9_rashi'),
      d9House: _readInt(json, 'd9_house'),
      retrograde: _readBool(json, 'retrograde'),
      combust: _readBool(json, 'combust'),
    );
  }
}

class ReportGrahaTable {
  const ReportGrahaTable({
    required this.sun,
    required this.moon,
    required this.mangal,
    required this.budha,
    required this.guru,
    required this.shukra,
    required this.shani,
    required this.rahu,
    required this.ketu,
    required this.spashthRahu,
    required this.spashthKetu,
    required this.lagna,
  });

  final ReportGrahaEntry sun;
  final ReportGrahaEntry moon;
  final ReportGrahaEntry mangal;
  final ReportGrahaEntry budha;
  final ReportGrahaEntry guru;
  final ReportGrahaEntry shukra;
  final ReportGrahaEntry shani;
  final ReportGrahaEntry rahu;
  final ReportGrahaEntry ketu;
  final ReportGrahaEntry spashthRahu;
  final ReportGrahaEntry spashthKetu;
  final ReportGrahaEntry lagna;

  ReportGrahaEntry entryByKey(String key) {
    switch (key) {
      case 'sun':
        return sun;
      case 'moon':
        return moon;
      case 'mangal':
        return mangal;
      case 'budha':
        return budha;
      case 'guru':
        return guru;
      case 'shukra':
        return shukra;
      case 'shani':
        return shani;
      case 'rahu':
        return rahu;
      case 'ketu':
        return ketu;
      case 'spashth_rahu':
        return spashthRahu;
      case 'spashth_ketu':
        return spashthKetu;
      case 'lagna':
        return lagna;
      default:
        throw ArgumentError('Unsupported graha key: $key');
    }
  }

  factory ReportGrahaTable.fromJson(Map<String, dynamic> json) {
    return ReportGrahaTable(
      sun: ReportGrahaEntry.fromJson(_readMap(json, 'sun')),
      moon: ReportGrahaEntry.fromJson(_readMap(json, 'moon')),
      mangal: ReportGrahaEntry.fromJson(_readMap(json, 'mangal')),
      budha: ReportGrahaEntry.fromJson(_readMap(json, 'budha')),
      guru: ReportGrahaEntry.fromJson(_readMap(json, 'guru')),
      shukra: ReportGrahaEntry.fromJson(_readMap(json, 'shukra')),
      shani: ReportGrahaEntry.fromJson(_readMap(json, 'shani')),
      rahu: ReportGrahaEntry.fromJson(_readMap(json, 'rahu')),
      ketu: ReportGrahaEntry.fromJson(_readMap(json, 'ketu')),
      spashthRahu: ReportGrahaEntry.fromJson(_readMap(json, 'spashth_rahu')),
      spashthKetu: ReportGrahaEntry.fromJson(_readMap(json, 'spashth_ketu')),
      lagna: ReportGrahaEntry.fromJson(_readMap(json, 'lagna')),
    );
  }
}

ReportVedicGraha _readVedicGraha(
  Map<String, dynamic> json,
  String prefix,
) {
  return ReportVedicGraha(
    rashi: _readString(json, '${prefix}_rashi'),
    nakshatra: _readString(json, '${prefix}_nakshatra'),
    pada: _readInt(json, '${prefix}_pada'),
  );
}

Map<String, dynamic> _readMap(Map<String, dynamic> json, String key) {
  if (!json.containsKey(key)) {
    throw FormatException('Missing required field "$key"');
  }
  return _asMap(json[key], key);
}

Map<String, dynamic> _asMap(Object? raw, String context) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((Object? key, Object? value) {
      return MapEntry(key.toString(), value);
    });
  }
  throw FormatException('Field "$context" must be an object');
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String) {
    return value;
  }
  throw FormatException('Field "$key" must be a string');
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    final parsed = double.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  throw FormatException('Field "$key" must be a number');
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) {
      return parsed;
    }
  }
  throw FormatException('Field "$key" must be an integer');
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  throw FormatException('Field "$key" must be a boolean');
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is List) {
    return value.map((Object? item) => item.toString()).toList(growable: false);
  }
  throw FormatException('Field "$key" must be a list');
}
