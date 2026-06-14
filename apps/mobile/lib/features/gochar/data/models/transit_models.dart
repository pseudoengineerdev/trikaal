import '../../../../app/models/custom_place_payload.dart';

/// Request for `/v1/transit/compute`. Natal birth details anchor the Moon and
/// Lagna; the optional [asOfDate] + observation place let the page browse the
/// transit sky for any day at the user's current location.
class TransitComputeRequest {
  const TransitComputeRequest({
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    this.customPlace,
    this.asOfDate,
    this.observationPlace,
    this.observationCustomPlace,
  });

  final String dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;
  final String? asOfDate;
  final String? observationPlace;
  final CustomPlacePayload? observationCustomPlace;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
      if (customPlace != null) 'custom_place': customPlace!.toJson(),
      if (asOfDate != null) 'as_of_date': asOfDate,
      if (observationPlace != null) 'observation_place': observationPlace,
      if (observationCustomPlace != null)
        'observation_custom_place': observationCustomPlace!.toJson(),
    };
  }
}

/// A name carried in both English and Sanskrit so the global terminology toggle
/// can pick the right one at render time.
class LocalizedName {
  const LocalizedName({required this.english, required this.vedic});

  final String english;
  final String vedic;

  factory LocalizedName.fromJson(Object? raw) {
    final map = _asMap(raw);
    return LocalizedName(
      english: _readString(map, 'english'),
      vedic: _readString(map, 'vedic'),
    );
  }
}

class TransitComputeResponse {
  const TransitComputeResponse({
    required this.asOf,
    required this.observationPlace,
    required this.natal,
    required this.planets,
    required this.saturn,
    required this.doubleTransit,
    required this.ashtakavarga,
    required this.highlights,
  });

  final GocharAsOf asOf;
  final GocharPlaceInfo observationPlace;
  final GocharNatal natal;
  final List<GocharPlanet> planets;
  final SaturnGochar saturn;
  final DoubleTransit doubleTransit;
  final AshtakavargaTables ashtakavarga;
  final List<GocharHighlight> highlights;

  factory TransitComputeResponse.fromJson(Map<String, dynamic> json) {
    return TransitComputeResponse(
      asOf: GocharAsOf.fromJson(_asMap(json['as_of'])),
      observationPlace: GocharPlaceInfo.fromJson(_asMap(json['observation_place'])),
      natal: GocharNatal.fromJson(_asMap(json['natal'])),
      planets: _asList(json['planets'])
          .map((Object? raw) => GocharPlanet.fromJson(_asMap(raw)))
          .toList(growable: false),
      saturn: SaturnGochar.fromJson(_asMap(json['saturn'])),
      doubleTransit: DoubleTransit.fromJson(_asMap(json['double_transit'])),
      ashtakavarga: AshtakavargaTables.fromJson(_asMap(json['ashtakavarga'])),
      highlights: _asList(json['highlights'])
          .map((Object? raw) => GocharHighlight.fromJson(_asMap(raw)))
          .toList(growable: false),
    );
  }

  GocharPlanet? planet(String key) {
    for (final planet in planets) {
      if (planet.key == key) {
        return planet;
      }
    }
    return null;
  }
}

class GocharAsOf {
  const GocharAsOf({
    required this.date,
    required this.localIso,
    required this.timezone,
    required this.isToday,
  });

  final String date;
  final String localIso;
  final String timezone;
  final bool isToday;

  factory GocharAsOf.fromJson(Map<String, dynamic> json) {
    return GocharAsOf(
      date: _readString(json, 'date'),
      localIso: _readString(json, 'local_iso'),
      timezone: _readString(json, 'timezone'),
      isToday: json['is_today'] == true,
    );
  }
}

class GocharPlaceInfo {
  const GocharPlaceInfo({
    required this.placeLabel,
    required this.timezone,
  });

  final String placeLabel;
  final String timezone;

  factory GocharPlaceInfo.fromJson(Map<String, dynamic> json) {
    return GocharPlaceInfo(
      placeLabel: _readString(json, 'place_label'),
      timezone: _readString(json, 'timezone'),
    );
  }
}

class GocharNatal {
  const GocharNatal({
    required this.moonRashiIndex,
    required this.moonRashi,
    required this.moonNakshatra,
    required this.moonPada,
    required this.lagnaRashiIndex,
    required this.lagnaRashi,
    required this.sunRashiIndex,
    required this.sunRashi,
  });

  final int moonRashiIndex;
  final LocalizedName moonRashi;
  final String moonNakshatra;
  final int moonPada;
  final int lagnaRashiIndex;
  final LocalizedName lagnaRashi;
  final int sunRashiIndex;
  final LocalizedName sunRashi;

  factory GocharNatal.fromJson(Map<String, dynamic> json) {
    return GocharNatal(
      moonRashiIndex: _readInt(json, 'moon_rashi_index'),
      moonRashi: LocalizedName.fromJson(json['moon_rashi']),
      moonNakshatra: _readString(json, 'moon_nakshatra'),
      moonPada: _readInt(json, 'moon_pada'),
      lagnaRashiIndex: _readInt(json, 'lagna_rashi_index'),
      lagnaRashi: LocalizedName.fromJson(json['lagna_rashi']),
      sunRashiIndex: _readInt(json, 'sun_rashi_index'),
      sunRashi: LocalizedName.fromJson(json['sun_rashi']),
    );
  }
}

class GocharPhala {
  const GocharPhala({
    required this.favourable,
    required this.hasVedhaRule,
    required this.vedhaObstructed,
    required this.vedhaHouseFromMoon,
    required this.vedhaBy,
  });

  final bool favourable;
  final bool hasVedhaRule;
  final bool vedhaObstructed;
  final int? vedhaHouseFromMoon;
  final String? vedhaBy;

  factory GocharPhala.fromJson(Map<String, dynamic> json) {
    return GocharPhala(
      favourable: json['favourable'] == true,
      hasVedhaRule: json['has_vedha_rule'] == true,
      vedhaObstructed: json['vedha_obstructed'] == true,
      vedhaHouseFromMoon: _readIntOrNull(json, 'vedha_house_from_moon'),
      vedhaBy: _readStringOrNull(json, 'vedha_by'),
    );
  }
}

class GocharIngress {
  const GocharIngress({
    required this.enteredIso,
    required this.enteredDate,
    required this.leavesIso,
    required this.leavesDate,
  });

  final String? enteredIso;
  final String? enteredDate;
  final String? leavesIso;
  final String? leavesDate;

  factory GocharIngress.fromJson(Map<String, dynamic> json) {
    return GocharIngress(
      enteredIso: _readStringOrNull(json, 'entered_iso'),
      enteredDate: _readStringOrNull(json, 'entered_date'),
      leavesIso: _readStringOrNull(json, 'leaves_iso'),
      leavesDate: _readStringOrNull(json, 'leaves_date'),
    );
  }
}

class GocharStation {
  const GocharStation({
    required this.motion,
    required this.nextStationIso,
    required this.nextStationDate,
    required this.sinceIso,
    required this.sinceDate,
  });

  final String motion;
  final String? nextStationIso;
  final String? nextStationDate;
  final String? sinceIso;
  final String? sinceDate;

  factory GocharStation.fromJson(Map<String, dynamic> json) {
    return GocharStation(
      motion: _readString(json, 'motion'),
      nextStationIso: _readStringOrNull(json, 'next_station_iso'),
      nextStationDate: _readStringOrNull(json, 'next_station_date'),
      sinceIso: _readStringOrNull(json, 'since_iso'),
      sinceDate: _readStringOrNull(json, 'since_date'),
    );
  }
}

class GocharAshtakavargaCell {
  const GocharAshtakavargaCell({
    required this.bindus,
    required this.maxBindus,
    required this.sarvaBindus,
  });

  /// This planet's own Bhinnashtakavarga bindus in its transit sign (0-8), or
  /// null for the nodes, which carry no Ashtakavarga.
  final int? bindus;
  final int maxBindus;

  /// Sarvashtakavarga total for the transit sign (sum over the seven planets).
  final int sarvaBindus;

  factory GocharAshtakavargaCell.fromJson(Map<String, dynamic> json) {
    return GocharAshtakavargaCell(
      bindus: _readIntOrNull(json, 'bindus'),
      maxBindus: _readInt(json, 'max_bindus', fallback: 8),
      sarvaBindus: _readInt(json, 'sarva_bindus'),
    );
  }
}

class GocharPlanet {
  const GocharPlanet({
    required this.key,
    required this.name,
    required this.rashiIndex,
    required this.rashi,
    required this.degreeInSign,
    required this.nakshatra,
    required this.pada,
    required this.motion,
    required this.retrograde,
    required this.combust,
    required this.dignity,
    required this.houseFromMoon,
    required this.houseFromLagna,
    required this.phalaFromMoon,
    required this.ingress,
    required this.station,
    required this.ashtakavarga,
  });

  final String key;
  final LocalizedName name;
  final int rashiIndex;
  final LocalizedName rashi;
  final double degreeInSign;
  final String nakshatra;
  final int pada;
  final String motion;
  final bool retrograde;
  final bool combust;
  final String dignity;
  final int houseFromMoon;
  final int houseFromLagna;
  final GocharPhala phalaFromMoon;
  final GocharIngress ingress;
  final GocharStation station;
  final GocharAshtakavargaCell ashtakavarga;

  int houseFor({required bool fromMoon}) =>
      fromMoon ? houseFromMoon : houseFromLagna;

  factory GocharPlanet.fromJson(Map<String, dynamic> json) {
    return GocharPlanet(
      key: _readString(json, 'key'),
      name: LocalizedName.fromJson(json['name']),
      rashiIndex: _readInt(json, 'rashi_index'),
      rashi: LocalizedName.fromJson(json['rashi']),
      degreeInSign: _readDouble(json, 'degree_in_sign'),
      nakshatra: _readString(json, 'nakshatra'),
      pada: _readInt(json, 'pada'),
      motion: _readString(json, 'motion'),
      retrograde: json['retrograde'] == true,
      combust: json['combust'] == true,
      dignity: _readString(json, 'dignity', fallback: 'none'),
      houseFromMoon: _readInt(json, 'house_from_moon'),
      houseFromLagna: _readInt(json, 'house_from_lagna'),
      phalaFromMoon: GocharPhala.fromJson(_asMap(json['phala_from_moon'])),
      ingress: GocharIngress.fromJson(_asMap(json['ingress'])),
      station: GocharStation.fromJson(_asMap(json['station'])),
      ashtakavarga:
          GocharAshtakavargaCell.fromJson(_asMap(json['ashtakavarga'])),
    );
  }
}

class SaturnPhaseLeg {
  const SaturnPhaseLeg({
    required this.phase,
    required this.houseFromMoon,
    required this.rashiIndex,
    required this.rashi,
    required this.startDate,
    required this.endDate,
  });

  final String phase;
  final int houseFromMoon;
  final int rashiIndex;
  final LocalizedName rashi;
  final String? startDate;
  final String? endDate;

  factory SaturnPhaseLeg.fromJson(Map<String, dynamic> json) {
    return SaturnPhaseLeg(
      phase: _readString(json, 'phase'),
      houseFromMoon: _readInt(json, 'house_from_moon'),
      rashiIndex: _readInt(json, 'rashi_index'),
      rashi: LocalizedName.fromJson(json['rashi']),
      startDate: _readStringOrNull(json, 'start_date'),
      endDate: _readStringOrNull(json, 'end_date'),
    );
  }
}

class SaturnGochar {
  const SaturnGochar({
    required this.houseFromMoon,
    required this.rashiIndex,
    required this.rashi,
    required this.status,
    required this.phase,
    required this.windowStartDate,
    required this.windowEndDate,
    required this.progressPercent,
    required this.legs,
    required this.nextStartDate,
  });

  /// One of `sade_sati`, `kantaka_dhaiya`, `ashtama_dhaiya`, `none`.
  final String status;
  final int houseFromMoon;
  final int rashiIndex;
  final LocalizedName rashi;

  /// `rising` / `peak` / `setting` while Sade Sati runs, else null.
  final String? phase;
  final String? windowStartDate;
  final String? windowEndDate;
  final double? progressPercent;
  final List<SaturnPhaseLeg> legs;
  final String? nextStartDate;

  bool get isActive => status != 'none';
  bool get isSadeSati => status == 'sade_sati';

  factory SaturnGochar.fromJson(Map<String, dynamic> json) {
    return SaturnGochar(
      status: _readString(json, 'status', fallback: 'none'),
      houseFromMoon: _readInt(json, 'house_from_moon'),
      rashiIndex: _readInt(json, 'rashi_index'),
      rashi: LocalizedName.fromJson(json['rashi']),
      phase: _readStringOrNull(json, 'phase'),
      windowStartDate: _readStringOrNull(json, 'window_start_date'),
      windowEndDate: _readStringOrNull(json, 'window_end_date'),
      progressPercent: _readDoubleOrNull(json, 'progress_percent'),
      legs: _asList(json['legs'])
          .map((Object? raw) => SaturnPhaseLeg.fromJson(_asMap(raw)))
          .toList(growable: false),
      nextStartDate: _readStringOrNull(json, 'next_start_date'),
    );
  }
}

class GocharHighlight {
  const GocharHighlight({
    required this.type,
    required this.planetKey,
    required this.date,
    required this.rashiIndex,
  });

  final String type;
  final String planetKey;
  final String? date;
  final int? rashiIndex;

  factory GocharHighlight.fromJson(Map<String, dynamic> json) {
    return GocharHighlight(
      type: _readString(json, 'type'),
      planetKey: _readString(json, 'planet_key'),
      date: _readStringOrNull(json, 'date'),
      rashiIndex: _readIntOrNull(json, 'rashi_index'),
    );
  }
}

class DoubleTransitSign {
  const DoubleTransitSign({
    required this.signIndex,
    required this.rashi,
    required this.jupiterRelation,
    required this.saturnRelation,
    required this.houseFromMoon,
    required this.houseFromLagna,
  });

  final int signIndex;
  final LocalizedName rashi;
  final String jupiterRelation; // occupies | aspect_5 | aspect_7 | aspect_9
  final String saturnRelation; // occupies | aspect_3 | aspect_7 | aspect_10
  final int houseFromMoon;
  final int houseFromLagna;

  factory DoubleTransitSign.fromJson(Map<String, dynamic> json) {
    return DoubleTransitSign(
      signIndex: _readInt(json, 'sign_index'),
      rashi: LocalizedName.fromJson(json['rashi']),
      jupiterRelation: _readString(json, 'jupiter_relation', fallback: 'none'),
      saturnRelation: _readString(json, 'saturn_relation', fallback: 'none'),
      houseFromMoon: _readInt(json, 'house_from_moon'),
      houseFromLagna: _readInt(json, 'house_from_lagna'),
    );
  }
}

class DoubleTransitBhava {
  const DoubleTransitBhava({
    required this.house,
    required this.signIndex,
    required this.rashi,
    required this.fromLagna,
    required this.fromMoon,
    required this.karakaKey,
    required this.karakaUnderDoubleTransit,
    required this.dashaLinked,
    required this.lordKey,
    required this.lordUnderDoubleTransit,
    required this.isDoubleTransit,
    required this.isEventWindow,
    required this.tier,
    required this.strengthScore,
    required this.significations,
  });

  final int house;
  final int signIndex;
  final LocalizedName rashi;
  final bool fromLagna;
  final bool fromMoon;
  final String karakaKey;
  final bool karakaUnderDoubleTransit;
  final bool dashaLinked;
  final String lordKey;
  final bool lordUnderDoubleTransit;
  final bool isDoubleTransit;
  final bool isEventWindow;
  final String tier; // event | strong | building | mild | quiet
  final int strengthScore; // weighted 0..7
  final List<String> significations;

  factory DoubleTransitBhava.fromJson(Map<String, dynamic> json) {
    return DoubleTransitBhava(
      house: _readInt(json, 'house'),
      signIndex: _readInt(json, 'sign_index'),
      rashi: LocalizedName.fromJson(json['rashi']),
      fromLagna: json['from_lagna'] == true,
      fromMoon: json['from_moon'] == true,
      karakaKey: _readString(json, 'karaka_key'),
      karakaUnderDoubleTransit: json['karaka_under_double_transit'] == true,
      dashaLinked: json['dasha_linked'] == true,
      lordKey: _readString(json, 'lord_key'),
      lordUnderDoubleTransit: json['lord_under_double_transit'] == true,
      isDoubleTransit: json['is_double_transit'] == true,
      isEventWindow: json['is_event_window'] == true,
      tier: _readString(json, 'tier', fallback: 'quiet'),
      strengthScore: _readInt(json, 'strength_score'),
      significations: _asList(json['significations'])
          .map((Object? raw) => raw is String ? raw : '')
          .where((String value) => value.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class DoubleTransit {
  const DoubleTransit({
    required this.jupiterSignIndex,
    required this.saturnSignIndex,
    required this.doubleTransitSignIndices,
    required this.active,
    required this.mahaDashaLord,
    required this.antarDashaLord,
    required this.headlineHouses,
    required this.eventWindowHouses,
    required this.signs,
    required this.bhavas,
  });

  final int jupiterSignIndex;
  final int saturnSignIndex;
  final List<int> doubleTransitSignIndices;
  final bool active;
  final String? mahaDashaLord;
  final String? antarDashaLord;
  final List<int> headlineHouses; // both frames (strong transit)
  final List<int> eventWindowHouses; // strong transit + dasha agrees
  final List<DoubleTransitSign> signs;
  final List<DoubleTransitBhava> bhavas;

  bool get hasEventWindow => eventWindowHouses.isNotEmpty;

  /// Bhavas the transit actually touches (from a frame), strongest first.
  List<DoubleTransitBhava> get activatedBhavas {
    final list =
        bhavas.where((b) => b.fromLagna || b.fromMoon).toList()
          ..sort((a, b) => b.strengthScore.compareTo(a.strengthScore));
    return list;
  }

  factory DoubleTransit.fromJson(Map<String, dynamic> json) {
    return DoubleTransit(
      jupiterSignIndex: _readInt(json, 'jupiter_sign_index'),
      saturnSignIndex: _readInt(json, 'saturn_sign_index'),
      doubleTransitSignIndices: _asList(json['double_transit_sign_indices'])
          .map((Object? raw) => (raw as num?)?.toInt() ?? 0)
          .toList(growable: false),
      active: json['active'] == true,
      mahaDashaLord: _readStringOrNull(json, 'maha_dasha_lord'),
      antarDashaLord: _readStringOrNull(json, 'antar_dasha_lord'),
      headlineHouses: _asList(json['headline_houses'])
          .map((Object? raw) => (raw as num?)?.toInt() ?? 0)
          .toList(growable: false),
      eventWindowHouses: _asList(json['event_window_houses'])
          .map((Object? raw) => (raw as num?)?.toInt() ?? 0)
          .toList(growable: false),
      signs: _asList(json['signs'])
          .map((Object? raw) => DoubleTransitSign.fromJson(_asMap(raw)))
          .toList(growable: false),
      bhavas: _asList(json['bhavas'])
          .map((Object? raw) => DoubleTransitBhava.fromJson(_asMap(raw)))
          .toList(growable: false),
    );
  }
}

class AshtakavargaTables {
  const AshtakavargaTables({required this.sarva, required this.bhinna});

  /// Sarvashtakavarga per sign (index 0 = Aries .. 11 = Pisces).
  final List<int> sarva;

  /// Bhinnashtakavarga per planet -> per-sign bindus.
  final Map<String, List<int>> bhinna;

  factory AshtakavargaTables.fromJson(Map<String, dynamic> json) {
    final bhinnaRaw = _asMap(json['bhinna']);
    return AshtakavargaTables(
      sarva: _asList(json['sarva'])
          .map((Object? raw) => (raw as num?)?.toInt() ?? 0)
          .toList(growable: false),
      bhinna: bhinnaRaw.map(
        (String key, Object? value) => MapEntry(
          key,
          _asList(value)
              .map((Object? raw) => (raw as num?)?.toInt() ?? 0)
              .toList(growable: false),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------- //
// JSON helpers (kept local so the model file is self-contained)
// --------------------------------------------------------------------------- //
Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Object?> _asList(Object? raw) {
  if (raw is List) {
    return raw;
  }
  return const <Object?>[];
}

String _readString(Map<String, dynamic> json, String key, {String fallback = ''}) {
  final value = json[key];
  return value is String ? value : fallback;
}

String? _readStringOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is String ? value : null;
}

int _readInt(Map<String, dynamic> json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

int? _readIntOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is num ? value.toInt() : null;
}

double _readDouble(Map<String, dynamic> json, String key, {double fallback = 0.0}) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  return fallback;
}

double? _readDoubleOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is num ? value.toDouble() : null;
}
