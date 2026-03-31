from __future__ import annotations

from datetime import datetime
from math import trunc
from zoneinfo import ZoneInfo

import swisseph as swe

from vedic_engine.domain import BirthEvent, CalculationProfile

DRIK_DISPLAY_OFFSET_DEG = 0.01
DRIK_LAGNA_DISPLAY_OFFSET_DEG = 0.182
NAKSHATRA_NAMES = [
    "Ashwini",
    "Bharani",
    "Krittika",
    "Rohini",
    "Mrigashirsha",
    "Ardra",
    "Punarvasu",
    "Pushya",
    "Ashlesha",
    "Magha",
    "P Phalguni",
    "U Phalguni",
    "Hasta",
    "Chitra",
    "Swati",
    "Vishakha",
    "Anuradha",
    "Jyeshtha",
    "Mula",
    "P Ashadha",
    "U Ashadha",
    "Shravana",
    "Dhanishta",
    "Shatabhisha",
    "P Bhadrapada",
    "U Bhadrapada",
    "Revati",
]
RASHI_NAMES = [
    "Mesh",
    "Vrish",
    "Mith",
    "Kark",
    "Simh",
    "Kany",
    "Tula",
    "Vrsc",
    "Dhanu",
    "Makar",
    "Kumb",
    "Meen",
]
DRIK_RASHI_ALIASES = {
    "Mith": "Mitu",
    "Makar": "Maka",
}
DRIK_ALIAS_TO_INTERNAL_RASHI = {value: key for key, value in DRIK_RASHI_ALIASES.items()}


def compute_chart_snapshot(
    *,
    birth_event: BirthEvent,
    profile: CalculationProfile,
) -> dict[str, object]:
    """Compute a minimal sidereal snapshot using Swiss Ephemeris."""
    local_dt = datetime.strptime(
        f"{birth_event.local_date} {birth_event.local_time}",
        "%Y-%m-%d %H:%M",
    ).replace(tzinfo=ZoneInfo(birth_event.timezone))
    utc_dt = local_dt.astimezone(ZoneInfo("UTC"))
    utc_hours = (
        utc_dt.hour
        + (utc_dt.minute / 60.0)
        + (utc_dt.second / 3600.0)
        + (utc_dt.microsecond / 3_600_000_000.0)
    )
    julian_day_utc = swe.julday(
        utc_dt.year,
        utc_dt.month,
        utc_dt.day,
        utc_hours,
        swe.GREG_CAL,
    )

    if profile.ayanamsha == "lahiri_chitrapaksha":
        swe.set_sid_mode(swe.SIDM_LAHIRI)

    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL | swe.FLG_SPEED
    sun_data, _ = swe.calc_ut(julian_day_utc, swe.SUN, flags)
    moon_data, _ = swe.calc_ut(julian_day_utc, swe.MOON, flags)
    mars_data, _ = swe.calc_ut(julian_day_utc, swe.MARS, flags)
    mercury_data, _ = swe.calc_ut(julian_day_utc, swe.MERCURY, flags)
    jupiter_data, _ = swe.calc_ut(julian_day_utc, swe.JUPITER, flags)
    venus_data, _ = swe.calc_ut(julian_day_utc, swe.VENUS, flags)
    saturn_data, _ = swe.calc_ut(julian_day_utc, swe.SATURN, flags)
    mean_node_data, _ = swe.calc_ut(julian_day_utc, swe.MEAN_NODE, flags)
    true_node_data, _ = swe.calc_ut(julian_day_utc, swe.TRUE_NODE, flags)
    _, ascmc = swe.houses_ex(
        julian_day_utc,
        birth_event.latitude,
        birth_event.longitude,
        b"P",
        swe.FLG_SIDEREAL,
    )
    lagna_raw = ascmc[0]

    sun_display = sun_data[0] - DRIK_DISPLAY_OFFSET_DEG
    moon_display = moon_data[0] - DRIK_DISPLAY_OFFSET_DEG
    mars_display = mars_data[0] - DRIK_DISPLAY_OFFSET_DEG
    mercury_display = mercury_data[0] - DRIK_DISPLAY_OFFSET_DEG
    jupiter_display = jupiter_data[0] - DRIK_DISPLAY_OFFSET_DEG
    venus_display = venus_data[0] - DRIK_DISPLAY_OFFSET_DEG
    saturn_display = saturn_data[0] - DRIK_DISPLAY_OFFSET_DEG
    mean_rahu_display = mean_node_data[0] - DRIK_DISPLAY_OFFSET_DEG
    mean_ketu_display = (mean_rahu_display + 180.0) % 360.0
    true_rahu_display = true_node_data[0] - DRIK_DISPLAY_OFFSET_DEG
    true_ketu_display = (true_rahu_display + 180.0) % 360.0
    lagna_display = lagna_raw + DRIK_LAGNA_DISPLAY_OFFSET_DEG
    sun_nakshatra, sun_pada = _nakshatra_and_pada(sun_display)
    moon_nakshatra, moon_pada = _nakshatra_and_pada(moon_display)
    lagna_nakshatra, lagna_pada = _nakshatra_and_pada(lagna_display)
    mars_nakshatra, mars_pada = _nakshatra_and_pada(mars_display)
    mercury_nakshatra, mercury_pada = _nakshatra_and_pada(mercury_display)
    jupiter_nakshatra, jupiter_pada = _nakshatra_and_pada(jupiter_display)
    venus_nakshatra, venus_pada = _nakshatra_and_pada(venus_display)
    saturn_nakshatra, saturn_pada = _nakshatra_and_pada(saturn_display)
    mean_rahu_nakshatra, mean_rahu_pada = _nakshatra_and_pada(mean_rahu_display)
    mean_ketu_nakshatra, mean_ketu_pada = _nakshatra_and_pada(mean_ketu_display)
    true_rahu_nakshatra, true_rahu_pada = _nakshatra_and_pada(true_rahu_display)
    true_ketu_nakshatra, true_ketu_pada = _nakshatra_and_pada(true_ketu_display)
    sun_rashi = _rashi_name(sun_display)
    moon_rashi = _rashi_name(moon_display)
    lagna_rashi = _rashi_name(lagna_display)
    mars_rashi = _rashi_name(mars_display)
    mercury_rashi = _rashi_name(mercury_display)
    jupiter_rashi = _rashi_name(jupiter_display)
    venus_rashi = _rashi_name(venus_display)
    saturn_rashi = _rashi_name(saturn_display)
    mean_rahu_rashi = _rashi_name(mean_rahu_display)
    mean_ketu_rashi = _rashi_name(mean_ketu_display)
    true_rahu_rashi = _rashi_name(true_rahu_display)
    true_ketu_rashi = _rashi_name(true_ketu_display)
    sun_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=sun_rashi)
    moon_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=moon_rashi)
    mangal_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=mars_rashi)
    budha_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=mercury_rashi)
    guru_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=jupiter_rashi)
    shukra_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=venus_rashi)
    shani_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=saturn_rashi)
    rahu_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=mean_rahu_rashi)
    ketu_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=mean_ketu_rashi)
    spashth_rahu_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=true_rahu_rashi)
    spashth_ketu_house = _house_from_lagna(lagna_rashi=lagna_rashi, target_rashi=true_ketu_rashi)

    return {
        "meta": {
            "status": "computed",
            "profile_id": profile.profile_id,
            "timezone": birth_event.timezone,
            "utc_iso": utc_dt.isoformat().replace("+00:00", "Z"),
        },
        "astronomy": {
            "julian_day_utc": round(julian_day_utc, 10),
            "sun_sidereal_deg": _truncate_2(sun_display),
            "moon_sidereal_deg": _truncate_2(moon_display),
            "mangal_sidereal_deg": _truncate_2(mars_display),
            "budha_sidereal_deg": _truncate_2(mercury_display),
            "guru_sidereal_deg": _truncate_2(jupiter_display),
            "shukra_sidereal_deg": _truncate_2(venus_display),
            "shani_sidereal_deg": _truncate_2(saturn_display),
            "rahu_sidereal_deg": _truncate_2(mean_rahu_display),
            "ketu_sidereal_deg": _truncate_2(mean_ketu_display),
            "spashth_rahu_sidereal_deg": _truncate_2(true_rahu_display),
            "spashth_ketu_sidereal_deg": _truncate_2(true_ketu_display),
            "lagna_sidereal_deg": _truncate_2(lagna_display),
            "sun_sidereal_deg_raw": round(sun_data[0], 8),
            "moon_sidereal_deg_raw": round(moon_data[0], 8),
            "mangal_sidereal_deg_raw": round(mars_data[0], 8),
            "budha_sidereal_deg_raw": round(mercury_data[0], 8),
            "guru_sidereal_deg_raw": round(jupiter_data[0], 8),
            "shukra_sidereal_deg_raw": round(venus_data[0], 8),
            "shani_sidereal_deg_raw": round(saturn_data[0], 8),
            "rahu_sidereal_deg_raw": round(mean_node_data[0], 8),
            "ketu_sidereal_deg_raw": round((mean_node_data[0] + 180.0) % 360.0, 8),
            "spashth_rahu_sidereal_deg_raw": round(true_node_data[0], 8),
            "spashth_ketu_sidereal_deg_raw": round((true_node_data[0] + 180.0) % 360.0, 8),
            "lagna_sidereal_deg_raw": round(lagna_raw, 8),
            "drik_display_offset_deg": DRIK_DISPLAY_OFFSET_DEG,
            "drik_lagna_display_offset_deg": DRIK_LAGNA_DISPLAY_OFFSET_DEG,
        },
        "vedic": {
            "sun_rashi": sun_rashi,
            "moon_rashi": moon_rashi,
            "lagna_rashi": lagna_rashi,
            "mangal_rashi": mars_rashi,
            "budha_rashi": mercury_rashi,
            "guru_rashi": jupiter_rashi,
            "shukra_rashi": venus_rashi,
            "shani_rashi": saturn_rashi,
            "rahu_rashi": mean_rahu_rashi,
            "ketu_rashi": mean_ketu_rashi,
            "spashth_rahu_rashi": true_rahu_rashi,
            "spashth_ketu_rashi": true_ketu_rashi,
            "sun_nakshatra": sun_nakshatra,
            "sun_pada": sun_pada,
            "moon_nakshatra": moon_nakshatra,
            "moon_pada": moon_pada,
            "lagna_nakshatra": lagna_nakshatra,
            "lagna_pada": lagna_pada,
            "mangal_nakshatra": mars_nakshatra,
            "mangal_pada": mars_pada,
            "budha_nakshatra": mercury_nakshatra,
            "budha_pada": mercury_pada,
            "guru_nakshatra": jupiter_nakshatra,
            "guru_pada": jupiter_pada,
            "shukra_nakshatra": venus_nakshatra,
            "shukra_pada": venus_pada,
            "shani_nakshatra": saturn_nakshatra,
            "shani_pada": saturn_pada,
            "rahu_nakshatra": mean_rahu_nakshatra,
            "rahu_pada": mean_rahu_pada,
            "ketu_nakshatra": mean_ketu_nakshatra,
            "ketu_pada": mean_ketu_pada,
            "spashth_rahu_nakshatra": true_rahu_nakshatra,
            "spashth_rahu_pada": true_rahu_pada,
            "spashth_ketu_nakshatra": true_ketu_nakshatra,
            "spashth_ketu_pada": true_ketu_pada,
        },
        "bhava": {
            "lagna_house": 1,
            "sun_house": sun_house,
            "moon_house": moon_house,
            "mangal_house": mangal_house,
            "budha_house": budha_house,
            "guru_house": guru_house,
            "shukra_house": shukra_house,
            "shani_house": shani_house,
            "rahu_house": rahu_house,
            "ketu_house": ketu_house,
            "spashth_rahu_house": spashth_rahu_house,
            "spashth_ketu_house": spashth_ketu_house,
        },
    }


def _nakshatra_and_pada(degree: float) -> tuple[str, int]:
    normalized_degree = degree % 360.0
    nakshatra_span = 360.0 / 27.0
    pada_span = nakshatra_span / 4.0
    nakshatra_index = int(normalized_degree // nakshatra_span)
    pada = int((normalized_degree % nakshatra_span) // pada_span) + 1
    return NAKSHATRA_NAMES[nakshatra_index], pada


def _rashi_name(degree: float) -> str:
    normalized_degree = degree % 360.0
    rashi_index = int(normalized_degree // 30.0)
    internal_name = RASHI_NAMES[rashi_index]
    return DRIK_RASHI_ALIASES.get(internal_name, internal_name)


def _truncate_2(value: float) -> float:
    return trunc(value * 100.0) / 100.0


def _house_from_lagna(*, lagna_rashi: str, target_rashi: str) -> int:
    lagna_internal = DRIK_ALIAS_TO_INTERNAL_RASHI.get(lagna_rashi, lagna_rashi)
    target_internal = DRIK_ALIAS_TO_INTERNAL_RASHI.get(target_rashi, target_rashi)
    lagna_index = RASHI_NAMES.index(lagna_internal)
    target_index = RASHI_NAMES.index(target_internal)
    return ((target_index - lagna_index) % 12) + 1
