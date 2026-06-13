"""Daily panchang computation for a location and date.

The panchang day runs from local sunrise to the next sunrise. All five limbs
(tithi, nakshatra, yoga, karana, vara) are reported with precise transition
times, alongside muhurta windows derived from the classical sunrise/sunset
proportional rules.
"""

from __future__ import annotations

from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

import swisseph as swe

from vedic_engine.calculator import (
    KARANA_NAMES_ENGLISH,
    KARANA_NAMES_VEDIC,
    TITHI_NAMES_ENGLISH,
    TITHI_NAMES_VEDIC,
    VARA_NAMES_ENGLISH,
    VARA_NAMES_VEDIC,
    YOGA_NAMES_ENGLISH,
    YOGA_NAMES_VEDIC,
)
from vedic_engine.dasha import NAKSHATRA_NAMES, NAKSHATRA_SPAN_DEG
from vedic_engine.hindu_calendar import (
    _amanta_lunar_month_info,
    _compute_sun_event_jd,
    _find_next_phase_jd,
    _format_lunar_month_name,
    _jd_at_local_hour,
    _jd_to_utc_datetime,
    _next_lunar_month_name,
    _sun_moon_sidereal_degrees,
)

_PLANETARY_FLAGS = swe.FLG_MOSEPH | swe.FLG_SIDEREAL | swe.FLG_SPEED
_TROPICAL_FLAGS = swe.FLG_MOSEPH | swe.FLG_SPEED

_TITHI_STEP_DEG = 12.0
_KARANA_STEP_DEG = 6.0
_YOGA_STEP_DEG = 360.0 / 27.0

_RITU_NAMES = ("Vasanta", "Grishma", "Varsha", "Sharad", "Hemanta", "Shishira")

_SIDEREAL_RASHI_NAMES = (
    "Mesha",
    "Vrishabha",
    "Mithuna",
    "Karka",
    "Simha",
    "Kanya",
    "Tula",
    "Vrischika",
    "Dhanu",
    "Makara",
    "Kumbha",
    "Meena",
)

_SAMVATSARA_NAMES = (
    "Prabhava",
    "Vibhava",
    "Shukla",
    "Pramoda",
    "Prajapati",
    "Angirasa",
    "Shrimukha",
    "Bhava",
    "Yuva",
    "Dhatri",
    "Ishvara",
    "Bahudhanya",
    "Pramathi",
    "Vikrama",
    "Vrisha",
    "Chitrabhanu",
    "Svabhanu",
    "Tarana",
    "Parthiva",
    "Vyaya",
    "Sarvajit",
    "Sarvadhari",
    "Virodhi",
    "Vikriti",
    "Khara",
    "Nandana",
    "Vijaya",
    "Jaya",
    "Manmatha",
    "Durmukha",
    "Hemalamba",
    "Vilambi",
    "Vikari",
    "Sharvari",
    "Plava",
    "Shubhakrit",
    "Shobhakrit",
    "Krodhi",
    "Vishvavasu",
    "Parabhava",
    "Plavanga",
    "Kilaka",
    "Saumya",
    "Sadharana",
    "Virodhikrit",
    "Paridhavi",
    "Pramadi",
    "Ananda",
    "Rakshasa",
    "Anala",
    "Pingala",
    "Kalayukta",
    "Siddharthi",
    "Raudra",
    "Durmati",
    "Dundubhi",
    "Rudhirodgari",
    "Raktakshi",
    "Krodhana",
    "Akshaya",
)

# Eighth-part index (1-8) of the sunrise->sunset span, by weekday (Sunday=0).
_RAHU_KALAM_PART = (8, 2, 7, 5, 6, 4, 3)
_YAMAGANDA_PART = (5, 4, 3, 2, 1, 7, 6)
_GULIKAI_PART = (7, 6, 5, 4, 3, 2, 1)

# Inauspicious day muhurtas (1-15 of the sunrise->sunset span), by weekday
# (Sunday=0). Tuesday carries an additional window at night (muhurta 7 of 15
# night muhurtas), encoded separately below.
_DUR_MUHURTAM_DAY = (
    (14,),
    (9,),
    (4,),
    (8,),
    (6,),
    (4,),
    (1, 2),
)
_DUR_MUHURTAM_NIGHT = (
    (),
    (),
    (7,),
    (),
    (),
    (),
    (),
)

# Varjyam start ghatis (out of 60 within the nakshatra span) per nakshatra,
# duration 4 ghatis on the same proportional scale.
_VARJYAM_START_GHATI = (
    50.0,  # Ashwini
    24.0,  # Bharani
    30.0,  # Krittika
    40.0,  # Rohini
    14.0,  # Mrigashirsha
    21.0,  # Ardra
    30.0,  # Punarvasu
    20.0,  # Pushya
    32.0,  # Ashlesha
    30.0,  # Magha
    20.0,  # P Phalguni
    18.0,  # U Phalguni
    21.0,  # Hasta
    20.0,  # Chitra
    14.0,  # Swati
    14.0,  # Vishakha
    10.0,  # Anuradha
    14.0,  # Jyeshtha
    20.0,  # Mula
    24.0,  # P Ashadha
    20.0,  # U Ashadha
    10.0,  # Shravana
    10.0,  # Dhanishta
    18.0,  # Shatabhisha
    16.0,  # P Bhadrapada
    24.0,  # U Bhadrapada
    30.0,  # Revati
)
_VARJYAM_DURATION_GHATI = 4.0

# Amrit kalam start ghatis (out of 60 within the nakshatra span) per
# nakshatra, duration 4 ghatis on the same proportional scale.
_AMRIT_KALAM_START_GHATI = (
    42.0,  # Ashwini
    48.0,  # Bharani
    54.0,  # Krittika
    52.0,  # Rohini
    38.0,  # Mrigashirsha
    35.0,  # Ardra
    54.0,  # Punarvasu
    44.0,  # Pushya
    56.0,  # Ashlesha
    54.0,  # Magha
    44.0,  # P Phalguni
    42.0,  # U Phalguni
    45.0,  # Hasta
    44.0,  # Chitra
    38.0,  # Swati
    38.0,  # Vishakha
    34.0,  # Anuradha
    38.0,  # Jyeshtha
    44.0,  # Mula
    48.0,  # P Ashadha
    44.0,  # U Ashadha
    34.0,  # Shravana
    34.0,  # Dhanishta
    42.0,  # Shatabhisha
    40.0,  # P Bhadrapada
    48.0,  # U Bhadrapada
    54.0,  # Revati
)
_AMRIT_KALAM_DURATION_GHATI = 4.0

_GANDA_MOOLA_NAKSHATRA_NUMBERS = frozenset({1, 9, 10, 18, 19, 27})

# Direction to avoid travelling toward, by weekday (Sunday=0).
_DISHA_SHOOLA = ("West", "East", "North", "North", "South", "West", "East")

_CHANDRABALAM_GOOD_HOUSES = frozenset({1, 3, 6, 7, 10, 11})
_TARABALAM_GOOD_TARAS = frozenset({2, 4, 6, 8, 9})

# Second half of Dhanishta (the Kumbha ingress) through the end of Revati.
_PANCHAKA_START_DEG = 300.0
_PANCHAKA_LABEL_BY_WEEKDAY = (
    "Roga Panchaka",
    "Raja Panchaka",
    "Agni Panchaka",
    "Nirdosha Panchaka",
    "Nirdosha Panchaka",
    "Chora Panchaka",
    "Mrityu Panchaka",
)

_GRAHA_NAMES_VEDIC = ("Surya", "Chandra", "Mangal", "Budha", "Guru", "Shukra", "Shani")
_GRAHA_NAMES_ENGLISH = ("Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn")
# Hora succession: each hora is ruled by the planet four places further along
# the Chaldean descending order, which yields this repeating cycle.
_HORA_SEQUENCE = (0, 5, 3, 1, 6, 4, 2)
_WEEKDAY_LORD_INDEX = (0, 1, 2, 3, 4, 5, 6)

_CHOGHADIYA_CYCLE = ("Udvega", "Chara", "Labha", "Amrita", "Kala", "Shubha", "Roga")
_CHOGHADIYA_QUALITY = {
    "Udvega": "inauspicious",
    "Chara": "auspicious",
    "Labha": "auspicious",
    "Amrita": "auspicious",
    "Kala": "inauspicious",
    "Shubha": "auspicious",
    "Roga": "inauspicious",
}
_CHOGHADIYA_DAY_START = (0, 3, 6, 2, 5, 1, 4)
_CHOGHADIYA_NIGHT_START = (5, 1, 4, 0, 3, 6, 2)


def compute_daily_panchang(
    *,
    target_date: str,
    timezone: str,
    latitude: float,
    longitude: float,
    elevation_m: float,
) -> dict[str, object]:
    """Compute the complete daily panchang for a date and location."""
    day = date.fromisoformat(target_date)
    tz = ZoneInfo(timezone)
    weekday_sunday0 = (day.weekday() + 1) % 7

    sunrise = _sun_event(day, timezone, latitude, longitude, elevation_m, swe.CALC_RISE)
    sunset = _sun_event(day, timezone, latitude, longitude, elevation_m, swe.CALC_SET)
    next_sunrise = _sun_event(
        day + timedelta(days=1), timezone, latitude, longitude, elevation_m, swe.CALC_RISE
    )
    previous_sunset = _sun_event(
        day - timedelta(days=1), timezone, latitude, longitude, elevation_m, swe.CALC_SET
    )

    if sunrise is not None and next_sunrise is not None:
        window_start_jd = sunrise[2]
        window_end_jd = next_sunrise[2]
    else:
        # Polar day/night: anchor the panchang day at local noon -> next noon.
        window_start_jd = _jd_at_local_hour(day, timezone, hour=12.0)
        window_end_jd = _jd_at_local_hour(day + timedelta(days=1), timezone, hour=12.0)

    sun_deg, moon_deg = _sun_moon_sidereal_degrees(window_start_jd)

    tithi_intervals = _element_intervals(
        window_start_jd=window_start_jd,
        window_end_jd=window_end_jd,
        angle_fn=_elongation_deg,
        speed_fn=_elongation_speed,
        step_deg=_TITHI_STEP_DEG,
    )
    nakshatra_intervals = _element_intervals(
        window_start_jd=window_start_jd,
        window_end_jd=window_end_jd,
        angle_fn=_moon_longitude_deg,
        speed_fn=_moon_speed,
        step_deg=NAKSHATRA_SPAN_DEG,
    )
    yoga_intervals = _element_intervals(
        window_start_jd=window_start_jd,
        window_end_jd=window_end_jd,
        angle_fn=_yoga_sum_deg,
        speed_fn=_yoga_speed,
        step_deg=_YOGA_STEP_DEG,
    )
    karana_intervals = _element_intervals(
        window_start_jd=window_start_jd,
        window_end_jd=window_end_jd,
        angle_fn=_elongation_deg,
        speed_fn=_elongation_speed,
        step_deg=_KARANA_STEP_DEG,
    )

    tithi_entries = [_tithi_entry(index, start, end, tz) for index, start, end in tithi_intervals]
    nakshatra_entries = [
        _nakshatra_entry(index, start, end, tz) for index, start, end in nakshatra_intervals
    ]
    yoga_entries = [_yoga_entry(index, start, end, tz) for index, start, end in yoga_intervals]
    karana_entries = [
        _karana_entry(index, start, end, tz) for index, start, end in karana_intervals
    ]

    sunrise_tithi_number = int(tithi_entries[0]["number"])
    paksha = "Shukla" if sunrise_tithi_number <= 15 else "Krishna"

    amanta_info = _amanta_lunar_month_info(window_start_jd)
    amanta_name = _format_lunar_month_name(amanta_info)
    if amanta_info.is_adhika or paksha == "Shukla":
        purnimanta_name = amanta_name
    else:
        purnimanta_name = _next_lunar_month_name(amanta_info.name)

    samvat = _compute_samvat(day, window_start_jd)

    moon_rashi_index = int((moon_deg % 360.0) // 30.0)
    sun_rashi_index = int((sun_deg % 360.0) // 30.0)
    moon_rashi_change = _moon_rashi_change(
        window_start_jd, window_end_jd, moon_rashi_index, tz
    )
    sun_nakshatra_index = int((sun_deg % 360.0) // NAKSHATRA_SPAN_DEG)
    sun_pada = int(((sun_deg % 360.0) % NAKSHATRA_SPAN_DEG) // (NAKSHATRA_SPAN_DEG / 4.0)) + 1
    moon_pada = int(((moon_deg % 360.0) % NAKSHATRA_SPAN_DEG) // (NAKSHATRA_SPAN_DEG / 4.0)) + 1

    tropical_sun_deg = _tropical_sun_deg(window_start_jd)
    ayana_ritu = {
        "ayana_sayana": _ayana_for_degree(tropical_sun_deg),
        "ayana_nirayana": _ayana_for_degree(sun_deg),
        "ritu_sayana": _ritu_for_degree(tropical_sun_deg),
        "ritu_nirayana": _ritu_for_degree(sun_deg),
    }

    moonrise = _moon_event(
        window_start_jd, window_end_jd, timezone, latitude, longitude, elevation_m, swe.CALC_RISE
    )
    moonset = _moon_event(
        window_start_jd, window_end_jd, timezone, latitude, longitude, elevation_m, swe.CALC_SET
    )

    auspicious: dict[str, object] = {}
    inauspicious: dict[str, object] = {}
    advanced: dict[str, object] = {
        "disha_shoola": _DISHA_SHOOLA[weekday_sunday0],
        "chandrabalam": _chandrabalam_rashis(moon_rashi_index),
        "tarabalam": _tarabalam_nakshatras(int(nakshatra_entries[0]["number"])),
        "panchaka": _panchaka(window_start_jd, window_end_jd, weekday_sunday0, tz),
    }

    if sunrise is not None and sunset is not None and next_sunrise is not None:
        sunrise_jd, sunset_jd, next_sunrise_jd = sunrise[2], sunset[2], next_sunrise[2]
        day_length_days = sunset_jd - sunrise_jd
        night_length_days = next_sunrise_jd - sunset_jd
        day_muhurta = day_length_days / 15.0
        night_muhurta = night_length_days / 15.0
        midday_jd = (sunrise_jd + sunset_jd) / 2.0
        midnight_jd = (sunset_jd + next_sunrise_jd) / 2.0

        auspicious["abhijit_muhurta"] = (
            None
            if weekday_sunday0 == 3
            else _jd_window(midday_jd - day_muhurta / 2.0, midday_jd + day_muhurta / 2.0, tz)
        )
        if previous_sunset is not None:
            prev_night_muhurta = (sunrise_jd - previous_sunset[2]) / 15.0
            auspicious["brahma_muhurta"] = _jd_window(
                sunrise_jd - (2.0 * prev_night_muhurta),
                sunrise_jd - prev_night_muhurta,
                tz,
            )
            auspicious["pratah_sandhya"] = _jd_window(
                sunrise_jd - (1.5 * prev_night_muhurta),
                sunrise_jd,
                tz,
            )
        auspicious["vijaya_muhurta"] = _jd_window(
            sunrise_jd + (10.0 * day_muhurta),
            sunrise_jd + (11.0 * day_muhurta),
            tz,
        )
        # Godhuli begins as the descending solar disc touches the horizon and
        # spans half a night muhurta.
        disc_touch = _sun_disc_bottom_set(
            day, timezone, latitude, longitude, elevation_m
        )
        godhuli_start_jd = disc_touch if disc_touch is not None else sunset_jd
        auspicious["godhuli_muhurta"] = _jd_window(
            godhuli_start_jd,
            godhuli_start_jd + (night_muhurta / 2.0),
            tz,
        )
        auspicious["sayahna_sandhya"] = _jd_window(
            sunset_jd,
            sunset_jd + (1.5 * night_muhurta),
            tz,
        )
        auspicious["nishita_muhurta"] = _jd_window(
            midnight_jd - night_muhurta / 2.0,
            midnight_jd + night_muhurta / 2.0,
            tz,
        )
        auspicious["amrit_kalam"] = _ghati_windows(
            nakshatra_intervals,
            window_start_jd,
            window_end_jd,
            _AMRIT_KALAM_START_GHATI,
            _AMRIT_KALAM_DURATION_GHATI,
            tz,
        )

        day_eighth = day_length_days / 8.0
        inauspicious["rahu_kalam"] = _eighth_part_window(
            sunrise_jd, day_eighth, _RAHU_KALAM_PART[weekday_sunday0], tz
        )
        inauspicious["yamaganda"] = _eighth_part_window(
            sunrise_jd, day_eighth, _YAMAGANDA_PART[weekday_sunday0], tz
        )
        inauspicious["gulikai_kalam"] = _eighth_part_window(
            sunrise_jd, day_eighth, _GULIKAI_PART[weekday_sunday0], tz
        )
        dur_windows = [
            _jd_window(
                sunrise_jd + ((muhurta - 1) * day_muhurta),
                sunrise_jd + (muhurta * day_muhurta),
                tz,
            )
            for muhurta in _DUR_MUHURTAM_DAY[weekday_sunday0]
        ]
        dur_windows.extend(
            _jd_window(
                sunset_jd + ((muhurta - 1) * night_muhurta),
                sunset_jd + (muhurta * night_muhurta),
                tz,
            )
            for muhurta in _DUR_MUHURTAM_NIGHT[weekday_sunday0]
        )
        inauspicious["dur_muhurtam"] = dur_windows
        inauspicious["varjyam"] = _ghati_windows(
            nakshatra_intervals,
            window_start_jd,
            window_end_jd,
            _VARJYAM_START_GHATI,
            _VARJYAM_DURATION_GHATI,
            tz,
        )
        inauspicious["bhadra"] = [
            {"start": entry["start"], "end": entry["end"]}
            for entry in karana_entries
            if entry["name_vedic"] == "Vishti"
        ]
        inauspicious["ganda_moola"] = [
            {
                "nakshatra": entry["name_vedic"],
                "start": entry["start"],
                "end": entry["end"],
            }
            for entry in nakshatra_entries
            if int(entry["number"]) in _GANDA_MOOLA_NAKSHATRA_NUMBERS
        ]

        advanced["hora_timeline"] = _hora_timeline(
            sunrise_jd, sunset_jd, next_sunrise_jd, weekday_sunday0, tz
        )
        advanced["choghadiya"] = {
            "day": _choghadiya_slots(
                sunrise_jd, sunset_jd, _CHOGHADIYA_DAY_START[weekday_sunday0], tz
            ),
            "night": _choghadiya_slots(
                sunset_jd, next_sunrise_jd, _CHOGHADIYA_NIGHT_START[weekday_sunday0], tz
            ),
        }

    return {
        "panchang_profile_id": "vedic_daily_panchang_v1",
        "date": day.isoformat(),
        "timezone": timezone,
        "location": {
            "latitude": latitude,
            "longitude": longitude,
            "elevation_m": elevation_m,
        },
        "weekday": {
            "number": weekday_sunday0 + 1,
            "name_vedic": VARA_NAMES_VEDIC[weekday_sunday0],
            "name_english": VARA_NAMES_ENGLISH[weekday_sunday0],
        },
        "sun": {
            "sunrise": _event_bundle(sunrise, tz),
            "sunset": _event_bundle(sunset, tz),
            "next_sunrise": _event_bundle(next_sunrise, tz),
            "solar_noon": (
                _jd_bundle((sunrise[2] + sunset[2]) / 2.0, tz)
                if sunrise is not None and sunset is not None
                else None
            ),
            "day_duration": (
                _duration(sunset[2] - sunrise[2])
                if sunrise is not None and sunset is not None
                else None
            ),
            "night_duration": (
                _duration(next_sunrise[2] - sunset[2])
                if sunset is not None and next_sunrise is not None
                else None
            ),
        },
        "moon": {
            "moonrise": _event_bundle(moonrise, tz),
            "moonset": _event_bundle(moonset, tz),
        },
        "tithi": tithi_entries,
        "nakshatra": nakshatra_entries,
        "yoga": yoga_entries,
        "karana": karana_entries,
        "lunar_month": {
            "amanta": amanta_name,
            "purnimanta": purnimanta_name,
            "paksha": paksha,
            "paksha_english": "Waxing" if paksha == "Shukla" else "Waning",
        },
        "samvat": samvat,
        "rashi": {
            "moon_rashi": _SIDEREAL_RASHI_NAMES[moon_rashi_index],
            "moon_rashi_change": moon_rashi_change,
            "sun_rashi": _SIDEREAL_RASHI_NAMES[sun_rashi_index],
            "sun_nakshatra": {
                "number": sun_nakshatra_index + 1,
                "name": NAKSHATRA_NAMES[sun_nakshatra_index],
                "pada": sun_pada,
            },
            "moon_nakshatra_pada": moon_pada,
        },
        "ayana_ritu": ayana_ritu,
        "auspicious": auspicious,
        "inauspicious": inauspicious,
        "advanced": advanced,
    }


def _elongation_deg(jd: float) -> float:
    sun_deg, moon_deg = _sun_moon_sidereal_degrees(jd)
    return (moon_deg - sun_deg) % 360.0


def _moon_longitude_deg(jd: float) -> float:
    _, moon_deg = _sun_moon_sidereal_degrees(jd)
    return moon_deg % 360.0


def _yoga_sum_deg(jd: float) -> float:
    sun_deg, moon_deg = _sun_moon_sidereal_degrees(jd)
    return (sun_deg + moon_deg) % 360.0


def _sun_moon_speeds(jd: float) -> tuple[float, float]:
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    sun_data, _ = swe.calc_ut(jd, swe.SUN, _PLANETARY_FLAGS)
    moon_data, _ = swe.calc_ut(jd, swe.MOON, _PLANETARY_FLAGS)
    return sun_data[3], moon_data[3]


def _elongation_speed(jd: float) -> float:
    sun_speed, moon_speed = _sun_moon_speeds(jd)
    return moon_speed - sun_speed


def _moon_speed(jd: float) -> float:
    return _sun_moon_speeds(jd)[1]


def _yoga_speed(jd: float) -> float:
    sun_speed, moon_speed = _sun_moon_speeds(jd)
    return moon_speed + sun_speed


def _find_next_angle_target_jd(
    jd_start: float,
    *,
    angle_fn,
    speed_fn,
    target_deg: float,
    max_days: float = 4.0,
) -> float:
    """Find the next moment the (monotonically increasing) angle hits target."""
    coarse_step = 0.2
    prev_jd = jd_start
    prev_angle = angle_fn(prev_jd)
    remaining = (target_deg - prev_angle) % 360.0
    traveled = 0.0
    steps = int(max_days / coarse_step) + 2
    for _ in range(steps):
        jd = prev_jd + coarse_step
        angle = angle_fn(jd)
        delta = (angle - prev_angle) % 360.0
        traveled += delta
        if traveled >= remaining:
            ratio = 1.0 - ((traveled - remaining) / delta) if delta > 0.0 else 0.0
            estimate = prev_jd + (coarse_step * ratio)
            return _refine_angle_target_jd(
                estimate,
                angle_fn=angle_fn,
                speed_fn=speed_fn,
                target_deg=target_deg,
                lo=prev_jd,
                hi=jd,
            )
        prev_jd = jd
        prev_angle = angle
    raise RuntimeError("Unable to locate the requested angle crossing.")


def _refine_angle_target_jd(
    jd: float,
    *,
    angle_fn,
    speed_fn,
    target_deg: float,
    lo: float,
    hi: float,
) -> float:
    for _ in range(30):
        error = ((angle_fn(jd) - target_deg) + 180.0) % 360.0 - 180.0
        if abs(error) < 1e-7:
            return jd
        speed = speed_fn(jd)
        if speed <= 1e-6:
            break
        jd = min(max(jd - (error / speed), lo), hi)
    return jd


def _element_intervals(
    *,
    window_start_jd: float,
    window_end_jd: float,
    angle_fn,
    speed_fn,
    step_deg: float,
    max_count: int = 8,
) -> list[tuple[int, float, float]]:
    """Intervals (element_index, start_jd, end_jd) covering the day window."""
    epsilon = 1e-5
    angle = angle_fn(window_start_jd)
    index = int((angle % 360.0) // step_deg)
    total = int(round(360.0 / step_deg))
    start_jd = _find_next_angle_target_jd(
        window_start_jd - 1.7,
        angle_fn=angle_fn,
        speed_fn=speed_fn,
        target_deg=(index * step_deg) % 360.0,
        max_days=1.8,
    )

    intervals: list[tuple[int, float, float]] = []
    current_index = index
    current_start = start_jd
    while len(intervals) < max_count:
        end_jd = _find_next_angle_target_jd(
            current_start + epsilon,
            angle_fn=angle_fn,
            speed_fn=speed_fn,
            target_deg=((current_index + 1) * step_deg) % 360.0,
        )
        intervals.append((current_index, current_start, end_jd))
        if end_jd >= window_end_jd - epsilon:
            break
        current_index = (current_index + 1) % total
        current_start = end_jd
    return intervals


def _tithi_entry(index: int, start_jd: float, end_jd: float, tz: ZoneInfo) -> dict[str, object]:
    number = index + 1
    return {
        "number": number,
        "name_vedic": TITHI_NAMES_VEDIC[index],
        "name_english": TITHI_NAMES_ENGLISH[index],
        "paksha": "Shukla" if number <= 15 else "Krishna",
        "paksha_english": "Waxing" if number <= 15 else "Waning",
        "start": _jd_bundle(start_jd, tz),
        "end": _jd_bundle(end_jd, tz),
    }


def _nakshatra_entry(
    index: int, start_jd: float, end_jd: float, tz: ZoneInfo
) -> dict[str, object]:
    return {
        "number": index + 1,
        "name_vedic": NAKSHATRA_NAMES[index],
        "name_english": NAKSHATRA_NAMES[index],
        "is_ganda_moola": (index + 1) in _GANDA_MOOLA_NAKSHATRA_NUMBERS,
        "start": _jd_bundle(start_jd, tz),
        "end": _jd_bundle(end_jd, tz),
    }


def _yoga_entry(index: int, start_jd: float, end_jd: float, tz: ZoneInfo) -> dict[str, object]:
    return {
        "number": index + 1,
        "name_vedic": YOGA_NAMES_VEDIC[index],
        "name_english": YOGA_NAMES_ENGLISH[index],
        "start": _jd_bundle(start_jd, tz),
        "end": _jd_bundle(end_jd, tz),
    }


def _karana_entry(index: int, start_jd: float, end_jd: float, tz: ZoneInfo) -> dict[str, object]:
    serial = index + 1
    name_vedic, name_english = _karana_names_for_serial(serial)
    return {
        "serial": serial,
        "name_vedic": name_vedic,
        "name_english": name_english,
        "is_vishti": name_vedic == "Vishti",
        "start": _jd_bundle(start_jd, tz),
        "end": _jd_bundle(end_jd, tz),
    }


def _karana_names_for_serial(serial: int) -> tuple[str, str]:
    if serial <= 1:
        return KARANA_NAMES_VEDIC[0], KARANA_NAMES_ENGLISH[0]
    if serial >= 58:
        fixed_index = min(serial - 50, 10)
        return KARANA_NAMES_VEDIC[fixed_index], KARANA_NAMES_ENGLISH[fixed_index]
    repeating_index = ((serial - 2) % 7) + 1
    return KARANA_NAMES_VEDIC[repeating_index], KARANA_NAMES_ENGLISH[repeating_index]


def _compute_samvat(day: date, anchor_jd: float) -> dict[str, object]:
    chaitra_start_jd = _chaitra_shukla_pratipada_jd(day.year)
    if anchor_jd >= chaitra_start_jd:
        shaka = day.year - 78
    else:
        shaka = day.year - 79
    vikram = shaka + 135
    return {
        "vikram": vikram,
        "vikram_samvatsara": _SAMVATSARA_NAMES[(vikram + 9) % 60],
        "shaka": shaka,
        "shaka_samvatsara": _SAMVATSARA_NAMES[(shaka + 11) % 60],
        "kali": shaka + 3179,
    }


def _chaitra_shukla_pratipada_jd(gregorian_year: int) -> float:
    """JD of the new moon that begins amanta Chaitra (adhika or nija)."""
    search_jd = _jd_at_local_hour(date(gregorian_year, 2, 1), "UTC", hour=0.0)
    for _ in range(4):
        new_moon_jd = _find_next_phase_jd(search_jd, target_phase=0.0)
        month_info = _amanta_lunar_month_info(new_moon_jd + 1.0)
        if month_info.name == "Chaitra":
            return new_moon_jd
        search_jd = new_moon_jd + 1.0
    raise RuntimeError("Unable to locate Chaitra Shukla Pratipada.")


def _moon_rashi_change(
    window_start_jd: float,
    window_end_jd: float,
    moon_rashi_index: int,
    tz: ZoneInfo,
) -> dict[str, object] | None:
    next_boundary_deg = ((moon_rashi_index + 1) * 30.0) % 360.0
    crossing_jd = _find_next_angle_target_jd(
        window_start_jd,
        angle_fn=_moon_longitude_deg,
        speed_fn=_moon_speed,
        target_deg=next_boundary_deg,
    )
    if crossing_jd > window_end_jd:
        return None
    return {
        "next_rashi": _SIDEREAL_RASHI_NAMES[(moon_rashi_index + 1) % 12],
        "at": _jd_bundle(crossing_jd, tz),
    }


def _tropical_sun_deg(jd: float) -> float:
    sun_data, _ = swe.calc_ut(jd, swe.SUN, _TROPICAL_FLAGS)
    return sun_data[0] % 360.0


def _ayana_for_degree(degree: float) -> str:
    normalized = degree % 360.0
    if normalized >= 270.0 or normalized < 90.0:
        return "Uttarayana"
    return "Dakshinayana"


def _ritu_for_degree(degree: float) -> str:
    index = int(((degree - 330.0) % 360.0) // 60.0)
    return _RITU_NAMES[index]


def _chandrabalam_rashis(moon_rashi_index: int) -> list[str]:
    favorable: list[str] = []
    for rashi_index in range(12):
        house = ((moon_rashi_index - rashi_index) % 12) + 1
        if house in _CHANDRABALAM_GOOD_HOUSES:
            favorable.append(_SIDEREAL_RASHI_NAMES[rashi_index])
    return favorable


def _tarabalam_nakshatras(current_nakshatra_number: int) -> list[str]:
    favorable: list[str] = []
    for janma_number in range(1, 28):
        count = ((current_nakshatra_number - janma_number) % 27) + 1
        tara = ((count - 1) % 9) + 1
        if tara in _TARABALAM_GOOD_TARAS:
            favorable.append(NAKSHATRA_NAMES[janma_number - 1])
    return favorable


def _panchaka(
    window_start_jd: float,
    window_end_jd: float,
    weekday_sunday0: int,
    tz: ZoneInfo,
) -> dict[str, object] | None:
    """Panchaka window: the Moon between Dhanishta's midpoint and Revati's end."""
    moon_deg = _moon_longitude_deg(window_start_jd)
    in_panchaka = moon_deg >= _PANCHAKA_START_DEG
    if in_panchaka:
        start_jd = window_start_jd
    else:
        try:
            # Only relevant when the Moon enters the panchaka arc today.
            start_jd = _find_next_angle_target_jd(
                window_start_jd,
                angle_fn=_moon_longitude_deg,
                speed_fn=_moon_speed,
                target_deg=_PANCHAKA_START_DEG,
                max_days=(window_end_jd - window_start_jd) + 0.01,
            )
        except RuntimeError:
            return None
        if start_jd >= window_end_jd:
            return None
    # The full arc spans 63°20'; allow for the slowest lunar motion.
    end_jd = _find_next_angle_target_jd(
        start_jd,
        angle_fn=_moon_longitude_deg,
        speed_fn=_moon_speed,
        target_deg=0.0,
        max_days=7.0,
    )
    return {
        "label": _PANCHAKA_LABEL_BY_WEEKDAY[weekday_sunday0],
        "start": _jd_bundle(start_jd, tz),
        "end": _jd_bundle(end_jd, tz),
        "active_at_sunrise": in_panchaka,
    }


def _ghati_windows(
    nakshatra_intervals: list[tuple[int, float, float]],
    window_start_jd: float,
    window_end_jd: float,
    start_ghati_table: tuple[float, ...],
    duration_ghati: float,
    tz: ZoneInfo,
) -> list[dict[str, object]]:
    """Windows positioned proportionally (in 60 ghatis) within each nakshatra."""
    windows: list[dict[str, object]] = []
    for index, start_jd, end_jd in nakshatra_intervals:
        span = end_jd - start_jd
        window_start = start_jd + (span * (start_ghati_table[index] / 60.0))
        window_end = window_start + (span * (duration_ghati / 60.0))
        if window_end <= window_start_jd or window_start >= window_end_jd:
            continue
        windows.append(_jd_window(window_start, window_end, tz))
    return windows


def _eighth_part_window(
    sunrise_jd: float, day_eighth: float, part_number: int, tz: ZoneInfo
) -> dict[str, object]:
    start_jd = sunrise_jd + ((part_number - 1) * day_eighth)
    return _jd_window(start_jd, start_jd + day_eighth, tz)


def _hora_timeline(
    sunrise_jd: float,
    sunset_jd: float,
    next_sunrise_jd: float,
    weekday_sunday0: int,
    tz: ZoneInfo,
) -> list[dict[str, object]]:
    day_hora = (sunset_jd - sunrise_jd) / 12.0
    night_hora = (next_sunrise_jd - sunset_jd) / 12.0
    sequence_start = _HORA_SEQUENCE.index(_WEEKDAY_LORD_INDEX[weekday_sunday0])
    timeline: list[dict[str, object]] = []
    for slot in range(24):
        lord_index = _HORA_SEQUENCE[(sequence_start + slot) % 7]
        if slot < 12:
            start_jd = sunrise_jd + (slot * day_hora)
            end_jd = start_jd + day_hora
            is_day = True
        else:
            start_jd = sunset_jd + ((slot - 12) * night_hora)
            end_jd = start_jd + night_hora
            is_day = False
        timeline.append(
            {
                "lord_vedic": _GRAHA_NAMES_VEDIC[lord_index],
                "lord_english": _GRAHA_NAMES_ENGLISH[lord_index],
                "is_day": is_day,
                "start": _jd_bundle(start_jd, tz),
                "end": _jd_bundle(end_jd, tz),
            }
        )
    return timeline


def _choghadiya_slots(
    span_start_jd: float, span_end_jd: float, cycle_start: int, tz: ZoneInfo
) -> list[dict[str, object]]:
    slot_length = (span_end_jd - span_start_jd) / 8.0
    slots: list[dict[str, object]] = []
    for slot in range(8):
        name = _CHOGHADIYA_CYCLE[(cycle_start + slot) % 7]
        start_jd = span_start_jd + (slot * slot_length)
        slots.append(
            {
                "name": name,
                "quality": _CHOGHADIYA_QUALITY[name],
                "start": _jd_bundle(start_jd, tz),
                "end": _jd_bundle(start_jd + slot_length, tz),
            }
        )
    return slots


def _sun_event(
    day: date,
    timezone: str,
    latitude: float,
    longitude: float,
    elevation_m: float,
    event_flag: int,
) -> tuple[datetime, datetime, float] | None:
    return _compute_sun_event_jd(
        current_date=day,
        timezone=timezone,
        latitude=latitude,
        longitude=longitude,
        elevation_m=elevation_m,
        event_flag=event_flag,
    )


def _moon_event(
    window_start_jd: float,
    window_end_jd: float,
    timezone: str,
    latitude: float,
    longitude: float,
    elevation_m: float,
    event_flag: int,
) -> tuple[datetime, datetime, float] | None:
    """First moon rise/set within the panchang day (sunrise to next sunrise)."""
    # Same observation convention as the solar events: disc center, no
    # atmospheric refraction.
    result, tret = swe.rise_trans(
        window_start_jd,
        swe.MOON,
        event_flag | swe.BIT_DISC_CENTER | swe.BIT_NO_REFRACTION,
        (longitude, latitude, elevation_m),
        0.0,
        15.0,
        swe.FLG_SWIEPH,
    )
    if result != 0 or tret[0] >= window_end_jd:
        return None
    event_utc = _jd_to_utc_datetime(tret[0])
    event_local = event_utc.astimezone(ZoneInfo(timezone))
    return event_utc, event_local, tret[0]


def _sun_disc_bottom_set(
    day: date,
    timezone: str,
    latitude: float,
    longitude: float,
    elevation_m: float,
) -> float | None:
    """JD when the lower limb of the setting sun touches the horizon."""
    jd_utc = _jd_at_local_hour(day, timezone, hour=0.0)
    result, tret = swe.rise_trans(
        jd_utc,
        swe.SUN,
        swe.CALC_SET | swe.BIT_DISC_BOTTOM | swe.BIT_NO_REFRACTION,
        (longitude, latitude, elevation_m),
        0.0,
        15.0,
        swe.FLG_SWIEPH,
    )
    if result != 0:
        return None
    return tret[0]


def _event_bundle(
    event: tuple[datetime, datetime, float] | None, tz: ZoneInfo
) -> dict[str, str] | None:
    if event is None:
        return None
    event_utc, event_local, _ = event
    return {
        "utc_iso": event_utc.isoformat().replace("+00:00", "Z"),
        "local_iso": event_local.isoformat(),
        "local_time": event_local.strftime("%H:%M"),
    }


def _jd_bundle(jd: float, tz: ZoneInfo) -> dict[str, str]:
    event_utc = _jd_to_utc_datetime(jd)
    event_local = event_utc.astimezone(tz)
    return {
        "utc_iso": event_utc.isoformat().replace("+00:00", "Z"),
        "local_iso": event_local.isoformat(),
        "local_time": event_local.strftime("%H:%M"),
    }


def _jd_window(start_jd: float, end_jd: float, tz: ZoneInfo) -> dict[str, object]:
    return {
        "start": _jd_bundle(start_jd, tz),
        "end": _jd_bundle(end_jd, tz),
    }


def _duration(span_days: float) -> dict[str, object]:
    total_minutes = int(round(span_days * 24.0 * 60.0))
    hours, minutes = divmod(total_minutes, 60)
    return {
        "minutes": total_minutes,
        "label": f"{hours}h {minutes:02d}m",
    }
