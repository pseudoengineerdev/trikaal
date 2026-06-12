import '../../../../app/models/custom_place_payload.dart';
import 'compute_chart_models.dart';

class ComputeHinduCalendarRequest {
  const ComputeHinduCalendarRequest({
    required this.year,
    required this.month,
    required this.monthType,
    required this.placeOfBirth,
    this.customPlace,
  });

  final int year;
  final int month;
  final String monthType;
  final String placeOfBirth;
  final CustomPlacePayload? customPlace;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'year': year,
      'month': month,
      'month_type': monthType,
      'place_of_birth': placeOfBirth,
      if (customPlace != null) 'custom_place': customPlace!.toJson(),
    };
  }
}

class ComputeHinduCalendarResponse {
  const ComputeHinduCalendarResponse({
    required this.profile,
    required this.normalizedInput,
    required this.resolvedPlace,
    required this.calendar,
  });

  final Map<String, dynamic> profile;
  final HinduCalendarNormalizedInput normalizedInput;
  final ResolvedPlace resolvedPlace;
  final HinduCalendarMonth calendar;

  factory ComputeHinduCalendarResponse.fromJson(Map<String, dynamic> json) {
    return ComputeHinduCalendarResponse(
      profile: _asMap(json['profile']),
      normalizedInput: HinduCalendarNormalizedInput.fromJson(
        _asMap(json['normalized_input']),
      ),
      resolvedPlace: ResolvedPlace.fromJson(_asMap(json['resolved_place'])),
      calendar: HinduCalendarMonth.fromJson(_asMap(json['calendar'])),
    );
  }
}

class HinduCalendarNormalizedInput {
  const HinduCalendarNormalizedInput({
    required this.year,
    required this.month,
    required this.monthType,
    required this.placeQuery,
  });

  final int year;
  final int month;
  final String monthType;
  final String placeQuery;

  factory HinduCalendarNormalizedInput.fromJson(Map<String, dynamic> json) {
    return HinduCalendarNormalizedInput(
      year: _readInt(json, 'year'),
      month: _readInt(json, 'month'),
      monthType: _readString(json, 'month_type'),
      placeQuery: _readString(json, 'place_query'),
    );
  }
}

class HinduCalendarMonth {
  const HinduCalendarMonth({
    required this.calendarProfileId,
    required this.monthType,
    required this.year,
    required this.month,
    required this.gregorianMonthLabel,
    required this.firstWeekdaySunday0,
    required this.dayCount,
    required this.timezone,
    required this.todayLocalDate,
    required this.selectedDate,
    required this.selectedDay,
    required this.lunarMonthsInView,
    required this.days,
  });

  final String calendarProfileId;
  final String monthType;
  final int year;
  final int month;
  final String gregorianMonthLabel;
  final int firstWeekdaySunday0;
  final int dayCount;
  final String timezone;
  final String todayLocalDate;
  final String selectedDate;
  final HinduCalendarMonthDay selectedDay;
  final List<String> lunarMonthsInView;
  final List<HinduCalendarMonthDay> days;

  factory HinduCalendarMonth.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'];
    if (daysRaw is! List) {
      throw const FormatException('Field "days" must be a list');
    }
    final selectedDayRaw = json['selected_day'];
    return HinduCalendarMonth(
      calendarProfileId: _readString(json, 'calendar_profile_id'),
      monthType: _readString(json, 'month_type'),
      year: _readInt(json, 'year'),
      month: _readInt(json, 'month'),
      gregorianMonthLabel: _readString(json, 'gregorian_month_label'),
      firstWeekdaySunday0: _readInt(json, 'first_weekday_sunday0'),
      dayCount: _readInt(json, 'day_count'),
      timezone: _readString(json, 'timezone'),
      todayLocalDate: _readString(json, 'today_local_date'),
      selectedDate: _readString(json, 'selected_date'),
      selectedDay: HinduCalendarMonthDay.fromJson(_asMap(selectedDayRaw)),
      lunarMonthsInView: _readStringList(json['lunar_months_in_view']),
      days: daysRaw
          .map(
            (Object? raw) =>
                HinduCalendarMonthDay.fromJson(_asMap(raw)),
          )
          .toList(growable: false),
    );
  }
}

class HinduCalendarMonthDay {
  const HinduCalendarMonthDay({
    required this.gregorianDate,
    required this.day,
    required this.weekdayIndexSunday0,
    required this.weekdayName,
    required this.sunriseLocalTime,
    required this.sunriseUtcIso,
    required this.sunriseLocalIso,
    required this.sunsetLocalTime,
    required this.lunarMonthName,
    required this.lunarDayOfMonth,
    required this.paksha,
    required this.pakshaEnglish,
    required this.tithiNumber,
    required this.tithiDay,
    required this.tithiNameVedic,
    required this.tithiNameEnglish,
    required this.sunSiderealDeg,
    required this.moonSiderealDeg,
    required this.sunRashi,
    required this.moonRashi,
    required this.nakshatraName,
  });

  final String gregorianDate;
  final int day;
  final int weekdayIndexSunday0;
  final String weekdayName;
  final String sunriseLocalTime;
  final String sunriseUtcIso;
  final String sunriseLocalIso;
  final String sunsetLocalTime;
  final String lunarMonthName;
  final int lunarDayOfMonth;
  final String paksha;
  final String pakshaEnglish;
  final int tithiNumber;
  final int tithiDay;
  final String tithiNameVedic;
  final String tithiNameEnglish;
  final double sunSiderealDeg;
  final double moonSiderealDeg;
  final String sunRashi;
  final String moonRashi;
  final String nakshatraName;

  factory HinduCalendarMonthDay.fromJson(Map<String, dynamic> json) {
    return HinduCalendarMonthDay(
      gregorianDate: _readString(json, 'gregorian_date'),
      day: _readInt(json, 'day'),
      weekdayIndexSunday0: _readInt(json, 'weekday_index_sunday0'),
      weekdayName: _readString(json, 'weekday_name'),
      sunriseLocalTime: _readString(json, 'sunrise_local_time'),
      sunriseUtcIso: _readString(json, 'sunrise_utc_iso'),
      sunriseLocalIso: _readString(json, 'sunrise_local_iso'),
      sunsetLocalTime: _readString(json, 'sunset_local_time'),
      lunarMonthName: _readString(json, 'lunar_month_name'),
      lunarDayOfMonth: _readInt(json, 'lunar_day_of_month'),
      paksha: _readString(json, 'paksha'),
      pakshaEnglish: _readString(json, 'paksha_english'),
      tithiNumber: _readInt(json, 'tithi_number'),
      tithiDay: _readInt(json, 'tithi_day'),
      tithiNameVedic: _readString(json, 'tithi_name_vedic'),
      tithiNameEnglish: _readString(json, 'tithi_name_english'),
      sunSiderealDeg: _readDouble(json, 'sun_sidereal_deg'),
      moonSiderealDeg: _readDouble(json, 'moon_sidereal_deg'),
      sunRashi: _readString(json, 'sun_rashi'),
      moonRashi: _readString(json, 'moon_rashi'),
      nakshatraName: _readString(json, 'nakshatra_name'),
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
    final parsedInt = int.tryParse(value.trim());
    if (parsedInt != null) {
      return parsedInt;
    }
    final parsedNum = num.tryParse(value.trim());
    if (parsedNum != null) {
      return parsedNum.toInt();
    }
  }
  return (value as num?)?.toInt() ?? 0;
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  if (value is String) {
    return num.tryParse(value.trim())?.toDouble() ?? 0.0;
  }
  return (value as num?)?.toDouble() ?? 0.0;
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
