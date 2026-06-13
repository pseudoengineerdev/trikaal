import '../../../../app/models/custom_place_payload.dart';
import '../../../charts/data/models/compute_chart_models.dart';

class ComputePanchangRequest {
  const ComputePanchangRequest({
    required this.date,
    required this.placeOfBirth,
    this.customPlace,
  });

  final String date;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'date': date,
      'place_of_birth': placeOfBirth,
      if (customPlace != null) 'custom_place': customPlace!.toJson(),
    };
  }
}

class ComputePanchangResponse {
  const ComputePanchangResponse({
    required this.profile,
    required this.resolvedPlace,
    required this.panchang,
  });

  final Map<String, dynamic> profile;
  final ResolvedPlace resolvedPlace;
  final DailyPanchang panchang;

  factory ComputePanchangResponse.fromJson(Map<String, dynamic> json) {
    return ComputePanchangResponse(
      profile: _asMap(json['profile']),
      resolvedPlace: ResolvedPlace.fromJson(_asMap(json['resolved_place'])),
      panchang: DailyPanchang.fromJson(_asMap(json['panchang'])),
    );
  }
}

class PanchangTimeBundle {
  const PanchangTimeBundle({
    required this.utcIso,
    required this.localIso,
    required this.localTime,
  });

  final String utcIso;
  final String localIso;
  final String localTime;

  factory PanchangTimeBundle.fromJson(Map<String, dynamic> json) {
    return PanchangTimeBundle(
      utcIso: _readString(json, 'utc_iso'),
      localIso: _readString(json, 'local_iso'),
      localTime: _readString(json, 'local_time'),
    );
  }

  static PanchangTimeBundle? maybeFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return PanchangTimeBundle.fromJson(_asMap(raw));
  }
}

class PanchangWindow {
  const PanchangWindow({required this.start, required this.end});

  final PanchangTimeBundle start;
  final PanchangTimeBundle end;

  factory PanchangWindow.fromJson(Map<String, dynamic> json) {
    return PanchangWindow(
      start: PanchangTimeBundle.fromJson(_asMap(json['start'])),
      end: PanchangTimeBundle.fromJson(_asMap(json['end'])),
    );
  }

  static PanchangWindow? maybeFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    return PanchangWindow.fromJson(_asMap(raw));
  }

  static List<PanchangWindow> listFromJson(Object? raw) {
    if (raw is! List) {
      return const <PanchangWindow>[];
    }
    return raw
        .whereType<Map>()
        .map((Map entry) => PanchangWindow.fromJson(_asMap(entry)))
        .toList(growable: false);
  }
}

/// One tithi/nakshatra/yoga/karana span within the panchang day.
class PanchangLimbEntry {
  const PanchangLimbEntry({
    required this.number,
    required this.nameVedic,
    required this.nameEnglish,
    required this.start,
    required this.end,
    this.paksha = '',
    this.pakshaEnglish = '',
    this.isGandaMoola = false,
    this.isVishti = false,
  });

  final int number;
  final String nameVedic;
  final String nameEnglish;
  final PanchangTimeBundle start;
  final PanchangTimeBundle end;
  final String paksha;
  final String pakshaEnglish;
  final bool isGandaMoola;
  final bool isVishti;

  factory PanchangLimbEntry.fromJson(Map<String, dynamic> json) {
    return PanchangLimbEntry(
      number: _readInt(json, json.containsKey('serial') ? 'serial' : 'number'),
      nameVedic: _readString(json, 'name_vedic'),
      nameEnglish: _readString(json, 'name_english'),
      start: PanchangTimeBundle.fromJson(_asMap(json['start'])),
      end: PanchangTimeBundle.fromJson(_asMap(json['end'])),
      paksha: _readString(json, 'paksha'),
      pakshaEnglish: _readString(json, 'paksha_english'),
      isGandaMoola: json['is_ganda_moola'] == true,
      isVishti: json['is_vishti'] == true,
    );
  }

  static List<PanchangLimbEntry> listFromJson(Object? raw) {
    if (raw is! List) {
      return const <PanchangLimbEntry>[];
    }
    return raw
        .whereType<Map>()
        .map((Map entry) => PanchangLimbEntry.fromJson(_asMap(entry)))
        .toList(growable: false);
  }
}

class PanchangDuration {
  const PanchangDuration({required this.minutes, required this.label});

  final int minutes;
  final String label;

  static PanchangDuration? maybeFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = _asMap(raw);
    return PanchangDuration(
      minutes: _readInt(map, 'minutes'),
      label: _readString(map, 'label'),
    );
  }
}

class PanchangSun {
  const PanchangSun({
    this.sunrise,
    this.sunset,
    this.nextSunrise,
    this.solarNoon,
    this.dayDuration,
    this.nightDuration,
  });

  final PanchangTimeBundle? sunrise;
  final PanchangTimeBundle? sunset;
  final PanchangTimeBundle? nextSunrise;
  final PanchangTimeBundle? solarNoon;
  final PanchangDuration? dayDuration;
  final PanchangDuration? nightDuration;

  factory PanchangSun.fromJson(Map<String, dynamic> json) {
    return PanchangSun(
      sunrise: PanchangTimeBundle.maybeFromJson(json['sunrise']),
      sunset: PanchangTimeBundle.maybeFromJson(json['sunset']),
      nextSunrise: PanchangTimeBundle.maybeFromJson(json['next_sunrise']),
      solarNoon: PanchangTimeBundle.maybeFromJson(json['solar_noon']),
      dayDuration: PanchangDuration.maybeFromJson(json['day_duration']),
      nightDuration: PanchangDuration.maybeFromJson(json['night_duration']),
    );
  }
}

class PanchangMoon {
  const PanchangMoon({this.moonrise, this.moonset});

  final PanchangTimeBundle? moonrise;
  final PanchangTimeBundle? moonset;

  factory PanchangMoon.fromJson(Map<String, dynamic> json) {
    return PanchangMoon(
      moonrise: PanchangTimeBundle.maybeFromJson(json['moonrise']),
      moonset: PanchangTimeBundle.maybeFromJson(json['moonset']),
    );
  }
}

class PanchangLunarMonth {
  const PanchangLunarMonth({
    required this.amanta,
    required this.purnimanta,
    required this.paksha,
    required this.pakshaEnglish,
  });

  final String amanta;
  final String purnimanta;
  final String paksha;
  final String pakshaEnglish;

  factory PanchangLunarMonth.fromJson(Map<String, dynamic> json) {
    return PanchangLunarMonth(
      amanta: _readString(json, 'amanta'),
      purnimanta: _readString(json, 'purnimanta'),
      paksha: _readString(json, 'paksha'),
      pakshaEnglish: _readString(json, 'paksha_english'),
    );
  }
}

class PanchangSamvat {
  const PanchangSamvat({
    required this.vikram,
    required this.vikramSamvatsara,
    required this.shaka,
    required this.shakaSamvatsara,
    required this.kali,
  });

  final int vikram;
  final String vikramSamvatsara;
  final int shaka;
  final String shakaSamvatsara;
  final int kali;

  factory PanchangSamvat.fromJson(Map<String, dynamic> json) {
    return PanchangSamvat(
      vikram: _readInt(json, 'vikram'),
      vikramSamvatsara: _readString(json, 'vikram_samvatsara'),
      shaka: _readInt(json, 'shaka'),
      shakaSamvatsara: _readString(json, 'shaka_samvatsara'),
      kali: _readInt(json, 'kali'),
    );
  }
}

class PanchangRashiChange {
  const PanchangRashiChange({required this.nextRashi, required this.at});

  final String nextRashi;
  final PanchangTimeBundle at;

  static PanchangRashiChange? maybeFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = _asMap(raw);
    return PanchangRashiChange(
      nextRashi: _readString(map, 'next_rashi'),
      at: PanchangTimeBundle.fromJson(_asMap(map['at'])),
    );
  }
}

class PanchangRashi {
  const PanchangRashi({
    required this.moonRashi,
    required this.sunRashi,
    required this.sunNakshatraName,
    required this.sunNakshatraPada,
    required this.moonNakshatraPada,
    this.moonRashiChange,
  });

  final String moonRashi;
  final String sunRashi;
  final String sunNakshatraName;
  final int sunNakshatraPada;
  final int moonNakshatraPada;
  final PanchangRashiChange? moonRashiChange;

  factory PanchangRashi.fromJson(Map<String, dynamic> json) {
    final sunNakshatra = _asMap(json['sun_nakshatra']);
    return PanchangRashi(
      moonRashi: _readString(json, 'moon_rashi'),
      sunRashi: _readString(json, 'sun_rashi'),
      sunNakshatraName: _readString(sunNakshatra, 'name'),
      sunNakshatraPada: _readInt(sunNakshatra, 'pada'),
      moonNakshatraPada: _readInt(json, 'moon_nakshatra_pada'),
      moonRashiChange: PanchangRashiChange.maybeFromJson(
        json['moon_rashi_change'],
      ),
    );
  }
}

class PanchangAyanaRitu {
  const PanchangAyanaRitu({
    required this.ayanaSayana,
    required this.ayanaNirayana,
    required this.rituSayana,
    required this.rituNirayana,
  });

  final String ayanaSayana;
  final String ayanaNirayana;
  final String rituSayana;
  final String rituNirayana;

  factory PanchangAyanaRitu.fromJson(Map<String, dynamic> json) {
    return PanchangAyanaRitu(
      ayanaSayana: _readString(json, 'ayana_sayana'),
      ayanaNirayana: _readString(json, 'ayana_nirayana'),
      rituSayana: _readString(json, 'ritu_sayana'),
      rituNirayana: _readString(json, 'ritu_nirayana'),
    );
  }
}

class PanchangAuspicious {
  const PanchangAuspicious({
    this.abhijitMuhurta,
    this.brahmaMuhurta,
    this.pratahSandhya,
    this.vijayaMuhurta,
    this.godhuliMuhurta,
    this.sayahnaSandhya,
    this.nishitaMuhurta,
    this.amritKalam = const <PanchangWindow>[],
  });

  final PanchangWindow? abhijitMuhurta;
  final PanchangWindow? brahmaMuhurta;
  final PanchangWindow? pratahSandhya;
  final PanchangWindow? vijayaMuhurta;
  final PanchangWindow? godhuliMuhurta;
  final PanchangWindow? sayahnaSandhya;
  final PanchangWindow? nishitaMuhurta;
  final List<PanchangWindow> amritKalam;

  factory PanchangAuspicious.fromJson(Map<String, dynamic> json) {
    return PanchangAuspicious(
      abhijitMuhurta: PanchangWindow.maybeFromJson(json['abhijit_muhurta']),
      brahmaMuhurta: PanchangWindow.maybeFromJson(json['brahma_muhurta']),
      pratahSandhya: PanchangWindow.maybeFromJson(json['pratah_sandhya']),
      vijayaMuhurta: PanchangWindow.maybeFromJson(json['vijaya_muhurta']),
      godhuliMuhurta: PanchangWindow.maybeFromJson(json['godhuli_muhurta']),
      sayahnaSandhya: PanchangWindow.maybeFromJson(json['sayahna_sandhya']),
      nishitaMuhurta: PanchangWindow.maybeFromJson(json['nishita_muhurta']),
      amritKalam: PanchangWindow.listFromJson(json['amrit_kalam']),
    );
  }
}

class PanchangGandaMoola {
  const PanchangGandaMoola({
    required this.nakshatra,
    required this.start,
    required this.end,
  });

  final String nakshatra;
  final PanchangTimeBundle start;
  final PanchangTimeBundle end;

  static List<PanchangGandaMoola> listFromJson(Object? raw) {
    if (raw is! List) {
      return const <PanchangGandaMoola>[];
    }
    return raw.whereType<Map>().map((Map entry) {
      final map = _asMap(entry);
      return PanchangGandaMoola(
        nakshatra: _readString(map, 'nakshatra'),
        start: PanchangTimeBundle.fromJson(_asMap(map['start'])),
        end: PanchangTimeBundle.fromJson(_asMap(map['end'])),
      );
    }).toList(growable: false);
  }
}

class PanchangInauspicious {
  const PanchangInauspicious({
    this.rahuKalam,
    this.yamaganda,
    this.gulikaiKalam,
    this.durMuhurtam = const <PanchangWindow>[],
    this.varjyam = const <PanchangWindow>[],
    this.bhadra = const <PanchangWindow>[],
    this.gandaMoola = const <PanchangGandaMoola>[],
  });

  final PanchangWindow? rahuKalam;
  final PanchangWindow? yamaganda;
  final PanchangWindow? gulikaiKalam;
  final List<PanchangWindow> durMuhurtam;
  final List<PanchangWindow> varjyam;
  final List<PanchangWindow> bhadra;
  final List<PanchangGandaMoola> gandaMoola;

  factory PanchangInauspicious.fromJson(Map<String, dynamic> json) {
    return PanchangInauspicious(
      rahuKalam: PanchangWindow.maybeFromJson(json['rahu_kalam']),
      yamaganda: PanchangWindow.maybeFromJson(json['yamaganda']),
      gulikaiKalam: PanchangWindow.maybeFromJson(json['gulikai_kalam']),
      durMuhurtam: PanchangWindow.listFromJson(json['dur_muhurtam']),
      varjyam: PanchangWindow.listFromJson(json['varjyam']),
      bhadra: PanchangWindow.listFromJson(json['bhadra']),
      gandaMoola: PanchangGandaMoola.listFromJson(json['ganda_moola']),
    );
  }
}

class PanchangHoraSlot {
  const PanchangHoraSlot({
    required this.lordVedic,
    required this.lordEnglish,
    required this.isDay,
    required this.start,
    required this.end,
  });

  final String lordVedic;
  final String lordEnglish;
  final bool isDay;
  final PanchangTimeBundle start;
  final PanchangTimeBundle end;

  static List<PanchangHoraSlot> listFromJson(Object? raw) {
    if (raw is! List) {
      return const <PanchangHoraSlot>[];
    }
    return raw.whereType<Map>().map((Map entry) {
      final map = _asMap(entry);
      return PanchangHoraSlot(
        lordVedic: _readString(map, 'lord_vedic'),
        lordEnglish: _readString(map, 'lord_english'),
        isDay: map['is_day'] == true,
        start: PanchangTimeBundle.fromJson(_asMap(map['start'])),
        end: PanchangTimeBundle.fromJson(_asMap(map['end'])),
      );
    }).toList(growable: false);
  }
}

class PanchangChoghadiyaSlot {
  const PanchangChoghadiyaSlot({
    required this.name,
    required this.quality,
    required this.start,
    required this.end,
  });

  final String name;
  final String quality;
  final PanchangTimeBundle start;
  final PanchangTimeBundle end;

  bool get isAuspicious => quality == 'auspicious';

  static List<PanchangChoghadiyaSlot> listFromJson(Object? raw) {
    if (raw is! List) {
      return const <PanchangChoghadiyaSlot>[];
    }
    return raw.whereType<Map>().map((Map entry) {
      final map = _asMap(entry);
      return PanchangChoghadiyaSlot(
        name: _readString(map, 'name'),
        quality: _readString(map, 'quality'),
        start: PanchangTimeBundle.fromJson(_asMap(map['start'])),
        end: PanchangTimeBundle.fromJson(_asMap(map['end'])),
      );
    }).toList(growable: false);
  }
}

class PanchangPanchaka {
  const PanchangPanchaka({
    required this.label,
    required this.start,
    required this.end,
    required this.activeAtSunrise,
  });

  final String label;
  final PanchangTimeBundle start;
  final PanchangTimeBundle end;
  final bool activeAtSunrise;

  static PanchangPanchaka? maybeFromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = _asMap(raw);
    return PanchangPanchaka(
      label: _readString(map, 'label'),
      start: PanchangTimeBundle.fromJson(_asMap(map['start'])),
      end: PanchangTimeBundle.fromJson(_asMap(map['end'])),
      activeAtSunrise: map['active_at_sunrise'] == true,
    );
  }
}

class PanchangAdvanced {
  const PanchangAdvanced({
    required this.dishaShoola,
    required this.chandrabalam,
    required this.tarabalam,
    this.panchaka,
    this.horaTimeline = const <PanchangHoraSlot>[],
    this.choghadiyaDay = const <PanchangChoghadiyaSlot>[],
    this.choghadiyaNight = const <PanchangChoghadiyaSlot>[],
  });

  final String dishaShoola;
  final List<String> chandrabalam;
  final List<String> tarabalam;
  final PanchangPanchaka? panchaka;
  final List<PanchangHoraSlot> horaTimeline;
  final List<PanchangChoghadiyaSlot> choghadiyaDay;
  final List<PanchangChoghadiyaSlot> choghadiyaNight;

  factory PanchangAdvanced.fromJson(Map<String, dynamic> json) {
    final choghadiya = _asMap(json['choghadiya']);
    return PanchangAdvanced(
      dishaShoola: _readString(json, 'disha_shoola'),
      chandrabalam: _readStringList(json['chandrabalam']),
      tarabalam: _readStringList(json['tarabalam']),
      panchaka: PanchangPanchaka.maybeFromJson(json['panchaka']),
      horaTimeline: PanchangHoraSlot.listFromJson(json['hora_timeline']),
      choghadiyaDay: PanchangChoghadiyaSlot.listFromJson(choghadiya['day']),
      choghadiyaNight: PanchangChoghadiyaSlot.listFromJson(choghadiya['night']),
    );
  }
}

class PanchangWeekday {
  const PanchangWeekday({
    required this.number,
    required this.nameVedic,
    required this.nameEnglish,
  });

  final int number;
  final String nameVedic;
  final String nameEnglish;

  factory PanchangWeekday.fromJson(Map<String, dynamic> json) {
    return PanchangWeekday(
      number: _readInt(json, 'number'),
      nameVedic: _readString(json, 'name_vedic'),
      nameEnglish: _readString(json, 'name_english'),
    );
  }
}

class DailyPanchang {
  const DailyPanchang({
    required this.panchangProfileId,
    required this.date,
    required this.timezone,
    required this.weekday,
    required this.sun,
    required this.moon,
    required this.tithi,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.lunarMonth,
    required this.samvat,
    required this.rashi,
    required this.ayanaRitu,
    required this.auspicious,
    required this.inauspicious,
    required this.advanced,
  });

  final String panchangProfileId;
  final String date;
  final String timezone;
  final PanchangWeekday weekday;
  final PanchangSun sun;
  final PanchangMoon moon;
  final List<PanchangLimbEntry> tithi;
  final List<PanchangLimbEntry> nakshatra;
  final List<PanchangLimbEntry> yoga;
  final List<PanchangLimbEntry> karana;
  final PanchangLunarMonth lunarMonth;
  final PanchangSamvat samvat;
  final PanchangRashi rashi;
  final PanchangAyanaRitu ayanaRitu;
  final PanchangAuspicious auspicious;
  final PanchangInauspicious inauspicious;
  final PanchangAdvanced advanced;

  factory DailyPanchang.fromJson(Map<String, dynamic> json) {
    return DailyPanchang(
      panchangProfileId: _readString(json, 'panchang_profile_id'),
      date: _readString(json, 'date'),
      timezone: _readString(json, 'timezone'),
      weekday: PanchangWeekday.fromJson(_asMap(json['weekday'])),
      sun: PanchangSun.fromJson(_asMap(json['sun'])),
      moon: PanchangMoon.fromJson(_asMap(json['moon'])),
      tithi: PanchangLimbEntry.listFromJson(json['tithi']),
      nakshatra: PanchangLimbEntry.listFromJson(json['nakshatra']),
      yoga: PanchangLimbEntry.listFromJson(json['yoga']),
      karana: PanchangLimbEntry.listFromJson(json['karana']),
      lunarMonth: PanchangLunarMonth.fromJson(_asMap(json['lunar_month'])),
      samvat: PanchangSamvat.fromJson(_asMap(json['samvat'])),
      rashi: PanchangRashi.fromJson(_asMap(json['rashi'])),
      ayanaRitu: PanchangAyanaRitu.fromJson(_asMap(json['ayana_ritu'])),
      auspicious: PanchangAuspicious.fromJson(_asMap(json['auspicious'])),
      inauspicious: PanchangInauspicious.fromJson(_asMap(json['inauspicious'])),
      advanced: PanchangAdvanced.fromJson(_asMap(json['advanced'])),
    );
  }
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return '';
  }
  return value.toString();
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.toInt();
  }
  if (value is String) {
    return num.tryParse(value.trim())?.toInt() ?? 0;
  }
  return (value as num?)?.toInt() ?? 0;
}

List<String> _readStringList(Object? raw) {
  final values = raw as List?;
  if (values == null) {
    return const <String>[];
  }
  return values
      .map((Object? value) => value?.toString() ?? '')
      .where((String value) => value.trim().isNotEmpty)
      .toList(growable: false);
}
