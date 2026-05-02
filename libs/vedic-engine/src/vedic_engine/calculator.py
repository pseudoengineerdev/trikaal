from __future__ import annotations

import contextlib
import importlib
import io
from datetime import datetime, timedelta
from functools import lru_cache
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
COMBUSTION_ORB_DEG = {
    "mangal": 17.0,
    "budha": 14.0,
    "guru": 11.0,
    "shukra": 10.0,
    "shani": 15.0,
}
VARA_NAMES_VEDIC = [
    "Ravivara",
    "Somavara",
    "Mangalavara",
    "Budhavara",
    "Guruvara",
    "Shukravara",
    "Shanivara",
]
VARA_NAMES_ENGLISH = [
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
]
TITHI_NAMES_VEDIC = [
    "Shukla Pratipada",
    "Shukla Dvitiya",
    "Shukla Tritiya",
    "Shukla Chaturthi",
    "Shukla Panchami",
    "Shukla Shashthi",
    "Shukla Saptami",
    "Shukla Ashtami",
    "Shukla Navami",
    "Shukla Dashami",
    "Shukla Ekadashi",
    "Shukla Dvadashi",
    "Shukla Trayodashi",
    "Shukla Chaturdashi",
    "Purnima",
    "Krishna Pratipada",
    "Krishna Dvitiya",
    "Krishna Tritiya",
    "Krishna Chaturthi",
    "Krishna Panchami",
    "Krishna Shashthi",
    "Krishna Saptami",
    "Krishna Ashtami",
    "Krishna Navami",
    "Krishna Dashami",
    "Krishna Ekadashi",
    "Krishna Dvadashi",
    "Krishna Trayodashi",
    "Krishna Chaturdashi",
    "Amavasya",
]
TITHI_NAMES_ENGLISH = [
    "Waxing Pratipada",
    "Waxing Dvitiya",
    "Waxing Tritiya",
    "Waxing Chaturthi",
    "Waxing Panchami",
    "Waxing Shashthi",
    "Waxing Saptami",
    "Waxing Ashtami",
    "Waxing Navami",
    "Waxing Dashami",
    "Waxing Ekadashi",
    "Waxing Dvadashi",
    "Waxing Trayodashi",
    "Waxing Chaturdashi",
    "Full Moon",
    "Waning Pratipada",
    "Waning Dvitiya",
    "Waning Tritiya",
    "Waning Chaturthi",
    "Waning Panchami",
    "Waning Shashthi",
    "Waning Saptami",
    "Waning Ashtami",
    "Waning Navami",
    "Waning Dashami",
    "Waning Ekadashi",
    "Waning Dvadashi",
    "Waning Trayodashi",
    "Waning Chaturdashi",
    "New Moon",
]
YOGA_NAMES_VEDIC = [
    "Vishkambha",
    "Priti",
    "Ayushman",
    "Saubhagya",
    "Shobhana",
    "Atiganda",
    "Sukarma",
    "Dhriti",
    "Shoola",
    "Ganda",
    "Vriddhi",
    "Dhruva",
    "Vyaghata",
    "Harshana",
    "Vajra",
    "Siddhi",
    "Vyatipata",
    "Variyana",
    "Parigha",
    "Shiva",
    "Siddha",
    "Sadhya",
    "Shubha",
    "Shukla",
    "Brahma",
    "Indra",
    "Vaidhriti",
]
YOGA_NAMES_ENGLISH = [
    "Vishkambha",
    "Priti",
    "Ayushman",
    "Saubhagya",
    "Shobhana",
    "Atiganda",
    "Sukarma",
    "Dhriti",
    "Shoola",
    "Ganda",
    "Vriddhi",
    "Dhruva",
    "Vyaghata",
    "Harshana",
    "Vajra",
    "Siddhi",
    "Vyatipata",
    "Variyana",
    "Parigha",
    "Shiva",
    "Siddha",
    "Sadhya",
    "Shubha",
    "Shukla",
    "Brahma",
    "Indra",
    "Vaidhriti",
]
KARANA_NAMES_VEDIC = [
    "Kimstughna",
    "Bava",
    "Balava",
    "Kaulava",
    "Taitila",
    "Garija",
    "Vanija",
    "Vishti",
    "Shakuni",
    "Chatushpada",
    "Naga",
]
KARANA_NAMES_ENGLISH = [
    "Kimstughna",
    "Bava",
    "Balava",
    "Kaulava",
    "Taitila",
    "Garija",
    "Vanija",
    "Vishti",
    "Shakuni",
    "Chatushpada",
    "Naga",
]
GRAHA_ORDER = [
    "sun",
    "moon",
    "mangal",
    "budha",
    "guru",
    "shukra",
    "shani",
    "rahu",
    "ketu",
    "spashth_rahu",
    "spashth_ketu",
    "lagna",
]
VARGA_FACTORS = tuple(range(1, 61))
_VARGA_GRAHA_KEYS = (
    "sun",
    "moon",
    "mangal",
    "budha",
    "guru",
    "shukra",
    "shani",
    "rahu",
    "ketu",
    "spashth_rahu",
    "spashth_ketu",
    "lagna",
)
_JHORA_PLANET_ID_BY_KEY = {
    "sun": 0,
    "moon": 1,
    "mangal": 2,
    "budha": 3,
    "guru": 4,
    "shukra": 5,
    "shani": 6,
    "rahu": 7,
    "ketu": 8,
    # We reserve ids 9/10 for true node placements in the generated divisional map.
    "spashth_rahu": 9,
    "spashth_ketu": 10,
}
_JHORA_KEY_BY_PLANET_ID = {value: key for key, value in _JHORA_PLANET_ID_BY_KEY.items()}


def compute_chart_snapshot(
    *,
    birth_event: BirthEvent,
    profile: CalculationProfile,
) -> dict[str, object]:
    """Compute a sidereal chart snapshot using Swiss Ephemeris."""
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

    display_degrees_by_key = {
        "sun": sun_display,
        "moon": moon_display,
        "mangal": mars_display,
        "budha": mercury_display,
        "guru": jupiter_display,
        "shukra": venus_display,
        "shani": saturn_display,
        "rahu": mean_rahu_display,
        "ketu": mean_ketu_display,
        "spashth_rahu": true_rahu_display,
        "spashth_ketu": true_ketu_display,
        "lagna": lagna_display,
    }
    varga_charts, varga_placements_by_key = _compute_varga_from_display_degrees(
        display_degrees_by_key=display_degrees_by_key,
    )

    sun_d9 = varga_placements_by_key["sun"]["d9"]
    moon_d9 = varga_placements_by_key["moon"]["d9"]
    mars_d9 = varga_placements_by_key["mangal"]["d9"]
    budha_d9 = varga_placements_by_key["budha"]["d9"]
    guru_d9 = varga_placements_by_key["guru"]["d9"]
    shukra_d9 = varga_placements_by_key["shukra"]["d9"]
    shani_d9 = varga_placements_by_key["shani"]["d9"]
    rahu_d9 = varga_placements_by_key["rahu"]["d9"]
    ketu_d9 = varga_placements_by_key["ketu"]["d9"]
    spashth_rahu_d9 = varga_placements_by_key["spashth_rahu"]["d9"]
    spashth_ketu_d9 = varga_placements_by_key["spashth_ketu"]["d9"]
    lagna_d9 = varga_placements_by_key["lagna"]["d9"]

    graha_table = {
        "sun": _graha_row(
            key="sun",
            degree=sun_display,
            degree_raw=sun_data[0],
            speed=sun_data[3],
            rashi=sun_rashi,
            nakshatra=sun_nakshatra,
            pada=sun_pada,
            house=sun_house,
            d9_rashi=str(sun_d9["rashi"]),
            d9_house=int(sun_d9["house"]),
            sun_degree=sun_display,
        ),
        "moon": _graha_row(
            key="moon",
            degree=moon_display,
            degree_raw=moon_data[0],
            speed=moon_data[3],
            rashi=moon_rashi,
            nakshatra=moon_nakshatra,
            pada=moon_pada,
            house=moon_house,
            d9_rashi=str(moon_d9["rashi"]),
            d9_house=int(moon_d9["house"]),
            sun_degree=sun_display,
        ),
        "mangal": _graha_row(
            key="mangal",
            degree=mars_display,
            degree_raw=mars_data[0],
            speed=mars_data[3],
            rashi=mars_rashi,
            nakshatra=mars_nakshatra,
            pada=mars_pada,
            house=mangal_house,
            d9_rashi=str(mars_d9["rashi"]),
            d9_house=int(mars_d9["house"]),
            sun_degree=sun_display,
        ),
        "budha": _graha_row(
            key="budha",
            degree=mercury_display,
            degree_raw=mercury_data[0],
            speed=mercury_data[3],
            rashi=mercury_rashi,
            nakshatra=mercury_nakshatra,
            pada=mercury_pada,
            house=budha_house,
            d9_rashi=str(budha_d9["rashi"]),
            d9_house=int(budha_d9["house"]),
            sun_degree=sun_display,
        ),
        "guru": _graha_row(
            key="guru",
            degree=jupiter_display,
            degree_raw=jupiter_data[0],
            speed=jupiter_data[3],
            rashi=jupiter_rashi,
            nakshatra=jupiter_nakshatra,
            pada=jupiter_pada,
            house=guru_house,
            d9_rashi=str(guru_d9["rashi"]),
            d9_house=int(guru_d9["house"]),
            sun_degree=sun_display,
        ),
        "shukra": _graha_row(
            key="shukra",
            degree=venus_display,
            degree_raw=venus_data[0],
            speed=venus_data[3],
            rashi=venus_rashi,
            nakshatra=venus_nakshatra,
            pada=venus_pada,
            house=shukra_house,
            d9_rashi=str(shukra_d9["rashi"]),
            d9_house=int(shukra_d9["house"]),
            sun_degree=sun_display,
        ),
        "shani": _graha_row(
            key="shani",
            degree=saturn_display,
            degree_raw=saturn_data[0],
            speed=saturn_data[3],
            rashi=saturn_rashi,
            nakshatra=saturn_nakshatra,
            pada=saturn_pada,
            house=shani_house,
            d9_rashi=str(shani_d9["rashi"]),
            d9_house=int(shani_d9["house"]),
            sun_degree=sun_display,
        ),
        "rahu": _graha_row(
            key="rahu",
            degree=mean_rahu_display,
            degree_raw=mean_node_data[0],
            speed=mean_node_data[3],
            rashi=mean_rahu_rashi,
            nakshatra=mean_rahu_nakshatra,
            pada=mean_rahu_pada,
            house=rahu_house,
            d9_rashi=str(rahu_d9["rashi"]),
            d9_house=int(rahu_d9["house"]),
            sun_degree=sun_display,
        ),
        "ketu": _graha_row(
            key="ketu",
            degree=mean_ketu_display,
            degree_raw=(mean_node_data[0] + 180.0) % 360.0,
            speed=mean_node_data[3],
            rashi=mean_ketu_rashi,
            nakshatra=mean_ketu_nakshatra,
            pada=mean_ketu_pada,
            house=ketu_house,
            d9_rashi=str(ketu_d9["rashi"]),
            d9_house=int(ketu_d9["house"]),
            sun_degree=sun_display,
        ),
        "spashth_rahu": _graha_row(
            key="spashth_rahu",
            degree=true_rahu_display,
            degree_raw=true_node_data[0],
            speed=true_node_data[3],
            rashi=true_rahu_rashi,
            nakshatra=true_rahu_nakshatra,
            pada=true_rahu_pada,
            house=spashth_rahu_house,
            d9_rashi=str(spashth_rahu_d9["rashi"]),
            d9_house=int(spashth_rahu_d9["house"]),
            sun_degree=sun_display,
        ),
        "spashth_ketu": _graha_row(
            key="spashth_ketu",
            degree=true_ketu_display,
            degree_raw=(true_node_data[0] + 180.0) % 360.0,
            speed=true_node_data[3],
            rashi=true_ketu_rashi,
            nakshatra=true_ketu_nakshatra,
            pada=true_ketu_pada,
            house=spashth_ketu_house,
            d9_rashi=str(spashth_ketu_d9["rashi"]),
            d9_house=int(spashth_ketu_d9["house"]),
            sun_degree=sun_display,
        ),
        "lagna": _graha_row(
            key="lagna",
            degree=lagna_display,
            degree_raw=lagna_raw,
            speed=0.0,
            rashi=lagna_rashi,
            nakshatra=lagna_nakshatra,
            pada=lagna_pada,
            house=1,
            d9_rashi=str(lagna_d9["rashi"]),
            d9_house=int(lagna_d9["house"]),
            sun_degree=sun_display,
        ),
    }

    panchanga = _compute_panchanga(
        local_dt=local_dt,
        julian_day_utc=julian_day_utc,
        latitude=birth_event.latitude,
        longitude=birth_event.longitude,
        elevation_m=birth_event.elevation_m,
        timezone=birth_event.timezone,
        sun_sidereal_deg=sun_display,
        moon_sidereal_deg=moon_display,
        moon_nakshatra=moon_nakshatra,
        moon_pada=moon_pada,
    )

    return {
        "meta": {
            "status": "computed",
            "profile_id": profile.profile_id,
            "timezone": birth_event.timezone,
            "utc_iso": utc_dt.isoformat().replace("+00:00", "Z"),
        },
        "panchanga": panchanga,
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
        "varga": varga_charts,
        "graha_table": graha_table,
    }


def _graha_row(
    *,
    key: str,
    degree: float,
    degree_raw: float,
    speed: float,
    rashi: str,
    nakshatra: str,
    pada: int,
    house: int,
    d9_rashi: str,
    d9_house: int,
    sun_degree: float,
) -> dict[str, object]:
    retrograde = _is_retrograde(key=key, speed=speed)
    combust = _is_combust(key=key, degree=degree, sun_degree=sun_degree)
    return {
        "key": key,
        "sidereal_deg": _truncate_2(degree),
        "sidereal_deg_raw": round(degree_raw, 8),
        "speed_deg_per_day": round(speed, 8),
        "rashi": rashi,
        "nakshatra": nakshatra,
        "pada": pada,
        "house": house,
        "d9_rashi": d9_rashi,
        "d9_house": d9_house,
        "retrograde": retrograde,
        "combust": combust,
    }


def _compute_varga_from_display_degrees(
    *,
    display_degrees_by_key: dict[str, float],
) -> tuple[dict[str, dict[str, object]], dict[str, dict[str, dict[str, object]]]]:
    charts_module = _load_jhora_charts_module()
    base_positions = _jhora_positions_from_display_degrees(
        display_degrees_by_key=display_degrees_by_key,
    )
    varga_placements_by_key = {
        key: {} for key in _VARGA_GRAHA_KEYS
    }
    varga_charts: dict[str, dict[str, object]] = {}

    for factor in VARGA_FACTORS:
        chart_key = _chart_key_for_factor(factor)
        raw_positions = charts_module.divisional_positions_from_rasi_positions(
            base_positions,
            divisional_chart_factor=factor,
            chart_method=1,
        )
        placements_for_chart = _normalize_jhora_division_positions(raw_positions)
        lagna_rashi = str(placements_for_chart["lagna"]["rashi"])
        for key in _VARGA_GRAHA_KEYS:
            placement = placements_for_chart[key]
            rashi = str(placement["rashi"])
            house = _house_from_lagna(
                lagna_rashi=lagna_rashi,
                target_rashi=rashi,
            )
            varga_placements_by_key[key][chart_key] = {
                "rashi": rashi,
                "house": house,
                "degree_in_sign": _truncate_4(float(placement["degree_in_sign"])),
            }
        varga_charts[chart_key] = _build_divisional_chart_from_placements(
            chart_key=chart_key,
            lagna_rashi=lagna_rashi,
            varga_placements_by_key=varga_placements_by_key,
        )

    return varga_charts, varga_placements_by_key


@lru_cache(maxsize=1)
def _load_jhora_charts_module():
    try:
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return importlib.import_module("jhora.horoscope.chart.charts")
    except Exception as exc:  # pragma: no cover - exercised via integration tests
        raise RuntimeError(
            "Divisional chart computation requires pyjhora to be installed and importable."
        ) from exc


def _jhora_positions_from_display_degrees(
    *,
    display_degrees_by_key: dict[str, float],
) -> list[list[object]]:
    positions: list[list[object]] = []
    ordered_keys = ["lagna", *[key for key in _VARGA_GRAHA_KEYS if key != "lagna"]]
    for key in ordered_keys:
        degree = display_degrees_by_key[key] % 360.0
        sign_index = int(degree // 30.0)
        degree_in_sign = degree % 30.0
        marker: object = "L" if key == "lagna" else _JHORA_PLANET_ID_BY_KEY[key]
        positions.append([marker, (sign_index, degree_in_sign)])
    return positions


def _normalize_jhora_division_positions(
    raw_positions: list[list[object]],
) -> dict[str, dict[str, object]]:
    normalized: dict[str, dict[str, object]] = {}
    for raw in raw_positions:
        if not isinstance(raw, (list, tuple)) or len(raw) < 2:
            continue
        marker = raw[0]
        raw_position = raw[1]
        if not isinstance(raw_position, (list, tuple)) or len(raw_position) < 2:
            continue
        if marker == "L":
            key = "lagna"
        elif isinstance(marker, int):
            key = _JHORA_KEY_BY_PLANET_ID.get(marker)
            if key is None:
                continue
        else:
            continue
        sign_index = int(raw_position[0])
        degree_in_sign = float(raw_position[1])
        normalized[key] = {
            "rashi": _rashi_name_from_index(sign_index),
            "degree_in_sign": degree_in_sign,
        }

    missing = [key for key in _VARGA_GRAHA_KEYS if key not in normalized]
    if missing:
        raise RuntimeError(f"Missing divisional placements for keys: {missing}")
    return normalized


def _build_divisional_chart_from_placements(
    *,
    chart_key: str,
    lagna_rashi: str,
    varga_placements_by_key: dict[str, dict[str, dict[str, object]]],
) -> dict[str, object]:
    lagna_internal = DRIK_ALIAS_TO_INTERNAL_RASHI.get(lagna_rashi, lagna_rashi)
    lagna_index = RASHI_NAMES.index(lagna_internal)
    houses: dict[str, dict[str, object]] = {}
    for house in range(1, 13):
        house_rashi_internal = RASHI_NAMES[(lagna_index + house - 1) % 12]
        house_rashi = DRIK_RASHI_ALIASES.get(house_rashi_internal, house_rashi_internal)
        houses[str(house)] = {
            "rashi": house_rashi,
            "occupants": [],
        }

    for key in GRAHA_ORDER:
        placement = varga_placements_by_key[key][chart_key]
        house = int(placement["house"])
        houses[str(house)]["occupants"].append(key)
    lagna_house = int(varga_placements_by_key["lagna"][chart_key]["house"])
    houses[str(lagna_house)]["occupants"].append("lagna")

    order_index = {key: idx for idx, key in enumerate(GRAHA_ORDER)}
    order_index["lagna"] = len(GRAHA_ORDER)
    for house in houses.values():
        occupants = house["occupants"]
        if isinstance(occupants, list):
            occupants.sort(key=lambda key: order_index.get(str(key), 999))

    graha_positions = {
        key: {
            "rashi": str(varga_placements_by_key[key][chart_key]["rashi"]),
            "house": int(varga_placements_by_key[key][chart_key]["house"]),
            "degree_in_sign": _truncate_4(
                float(varga_placements_by_key[key][chart_key]["degree_in_sign"])
            ),
        }
        for key in GRAHA_ORDER
    }

    return {
        "lagna_rashi": lagna_rashi,
        "houses": houses,
        "graha_positions": graha_positions,
    }


def _chart_key_for_factor(factor: int) -> str:
    if factor < 1 or factor > 60:
        raise ValueError(f"Unsupported varga factor: {factor}")
    return f"d{factor}"


def _rashi_name_from_index(index: int) -> str:
    internal_name = RASHI_NAMES[index % 12]
    return DRIK_RASHI_ALIASES.get(internal_name, internal_name)


def _is_retrograde(*, key: str, speed: float) -> bool:
    if key in {"sun", "moon", "lagna"}:
        return False
    return speed < 0.0


def _is_combust(*, key: str, degree: float, sun_degree: float) -> bool:
    orb = COMBUSTION_ORB_DEG.get(key)
    if orb is None:
        return False
    distance = _angular_distance(degree, sun_degree)
    return distance <= orb


def _angular_distance(left: float, right: float) -> float:
    raw = abs((left - right) % 360.0)
    return min(raw, 360.0 - raw)


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


def _truncate_4(value: float) -> float:
    return trunc(value * 10_000.0) / 10_000.0


def _house_from_lagna(*, lagna_rashi: str, target_rashi: str) -> int:
    lagna_internal = DRIK_ALIAS_TO_INTERNAL_RASHI.get(lagna_rashi, lagna_rashi)
    target_internal = DRIK_ALIAS_TO_INTERNAL_RASHI.get(target_rashi, target_rashi)
    lagna_index = RASHI_NAMES.index(lagna_internal)
    target_index = RASHI_NAMES.index(target_internal)
    return ((target_index - lagna_index) % 12) + 1


def _compute_panchanga(
    *,
    local_dt: datetime,
    julian_day_utc: float,
    latitude: float,
    longitude: float,
    elevation_m: float,
    timezone: str,
    sun_sidereal_deg: float,
    moon_sidereal_deg: float,
    moon_nakshatra: str,
    moon_pada: int,
) -> dict[str, object]:
    vara_index = local_dt.weekday()
    vara_number = ((vara_index + 1) % 7) + 1
    vara_vedic = VARA_NAMES_VEDIC[vara_number - 1]
    vara_english = VARA_NAMES_ENGLISH[vara_number - 1]

    tithi_phase = (moon_sidereal_deg - sun_sidereal_deg) % 360.0
    tithi_number = int(tithi_phase // 12.0) + 1
    tithi_vedic = TITHI_NAMES_VEDIC[tithi_number - 1]
    tithi_english = TITHI_NAMES_ENGLISH[tithi_number - 1]
    paksha = "Shukla" if tithi_number <= 15 else "Krishna"
    paksha_english = "Waxing" if tithi_number <= 15 else "Waning"
    tithi_progress = ((tithi_phase % 12.0) / 12.0) * 100.0

    yoga_sum = (sun_sidereal_deg + moon_sidereal_deg) % 360.0
    yoga_number = int(yoga_sum // (360.0 / 27.0)) + 1
    yoga_vedic = YOGA_NAMES_VEDIC[yoga_number - 1]
    yoga_english = YOGA_NAMES_ENGLISH[yoga_number - 1]
    yoga_progress = ((yoga_sum % (360.0 / 27.0)) / (360.0 / 27.0)) * 100.0

    karana_serial = int(tithi_phase // 6.0) + 1
    karana_vedic, karana_english = _karana_name_for_serial(karana_serial)
    karana_progress = ((tithi_phase % 6.0) / 6.0) * 100.0

    nakshatra_span = 360.0 / 27.0
    nakshatra_number = int((moon_sidereal_deg % 360.0) // nakshatra_span) + 1
    nakshatra_progress = (((moon_sidereal_deg % 360.0) % nakshatra_span) / nakshatra_span) * 100.0

    sunrise_utc, sunrise_local = _compute_sun_event(
        local_dt=local_dt,
        latitude=latitude,
        longitude=longitude,
        elevation_m=elevation_m,
        timezone=timezone,
        rsmi=swe.CALC_RISE,
    )
    sunset_utc, sunset_local = _compute_sun_event(
        local_dt=local_dt,
        latitude=latitude,
        longitude=longitude,
        elevation_m=elevation_m,
        timezone=timezone,
        rsmi=swe.CALC_SET,
    )

    return {
        "vara": {
            "number": vara_number,
            "name_vedic": vara_vedic,
            "name_english": vara_english,
        },
        "tithi": {
            "number": tithi_number,
            "paksha": paksha,
            "paksha_english": paksha_english,
            "name_vedic": tithi_vedic,
            "name_english": tithi_english,
            "progress_percent": round(tithi_progress, 2),
        },
        "nakshatra": {
            "number": nakshatra_number,
            "name_vedic": moon_nakshatra,
            "name_english": moon_nakshatra,
            "pada": moon_pada,
            "progress_percent": round(nakshatra_progress, 2),
        },
        "yoga": {
            "number": yoga_number,
            "name_vedic": yoga_vedic,
            "name_english": yoga_english,
            "progress_percent": round(yoga_progress, 2),
        },
        "karana": {
            "serial": karana_serial,
            "name_vedic": karana_vedic,
            "name_english": karana_english,
            "progress_percent": round(karana_progress, 2),
        },
        "sunrise": {
            "utc_iso": sunrise_utc.isoformat().replace("+00:00", "Z"),
            "local_iso": sunrise_local.isoformat(),
            "local_time": sunrise_local.strftime("%H:%M"),
        },
        "sunset": {
            "utc_iso": sunset_utc.isoformat().replace("+00:00", "Z"),
            "local_iso": sunset_local.isoformat(),
            "local_time": sunset_local.strftime("%H:%M"),
        },
    }


def _karana_name_for_serial(karana_serial: int) -> tuple[str, str]:
    if karana_serial <= 1:
        return KARANA_NAMES_VEDIC[0], KARANA_NAMES_ENGLISH[0]
    if karana_serial >= 58:
        fixed_index = min(karana_serial - 50, 10)
        return KARANA_NAMES_VEDIC[fixed_index], KARANA_NAMES_ENGLISH[fixed_index]
    repeating_index = ((karana_serial - 2) % 7) + 1
    return KARANA_NAMES_VEDIC[repeating_index], KARANA_NAMES_ENGLISH[repeating_index]


def _compute_sun_event(
    *,
    local_dt: datetime,
    latitude: float,
    longitude: float,
    elevation_m: float,
    timezone: str,
    rsmi: int,
) -> tuple[datetime, datetime]:
    local_midnight = local_dt.replace(hour=0, minute=0, second=0, microsecond=0)
    utc_midnight = local_midnight.astimezone(ZoneInfo("UTC"))
    utc_hours = (
        utc_midnight.hour
        + (utc_midnight.minute / 60.0)
        + (utc_midnight.second / 3600.0)
        + (utc_midnight.microsecond / 3_600_000_000.0)
    )
    jd_utc = swe.julday(
        utc_midnight.year,
        utc_midnight.month,
        utc_midnight.day,
        utc_hours,
        swe.GREG_CAL,
    )
    _, tret = swe.rise_trans(
        jd_utc,
        swe.SUN,
        rsmi,
        (longitude, latitude, elevation_m),
        0.0,
        15.0,
        swe.FLG_SWIEPH,
    )
    event_utc = _jd_to_utc_datetime(tret[0])
    event_local = event_utc.astimezone(ZoneInfo(timezone))
    return event_utc, event_local


def _jd_to_utc_datetime(jd_utc: float) -> datetime:
    year, month, day, hour = swe.revjul(jd_utc, swe.GREG_CAL)
    midnight_utc = datetime(year, month, day, tzinfo=ZoneInfo("UTC"))
    return midnight_utc + timedelta(hours=hour)
