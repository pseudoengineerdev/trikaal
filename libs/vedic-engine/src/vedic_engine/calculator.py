from __future__ import annotations

from datetime import datetime
from math import trunc
from zoneinfo import ZoneInfo

import swisseph as swe

from vedic_engine.domain import BirthEvent, CalculationProfile

REFERENCE_DISPLAY_OFFSET_DEG = 0.01
REFERENCE_LAGNA_DISPLAY_OFFSET_DEG = 0.182
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
REFERENCE_RASHI_ALIASES = {
    "Mith": "Mitu",
    "Makar": "Maka",
}
REFERENCE_ALIAS_TO_INTERNAL_RASHI = {value: key for key, value in REFERENCE_RASHI_ALIASES.items()}
COMBUSTION_ORB_DEG = {
    "mangal": 17.0,
    "budha": 14.0,
    "guru": 11.0,
    "shukra": 10.0,
    "shani": 15.0,
}
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

    sun_display = sun_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    moon_display = moon_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    mars_display = mars_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    mercury_display = mercury_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    jupiter_display = jupiter_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    venus_display = venus_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    saturn_display = saturn_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    mean_rahu_display = mean_node_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    mean_ketu_display = (mean_rahu_display + 180.0) % 360.0
    true_rahu_display = true_node_data[0] - REFERENCE_DISPLAY_OFFSET_DEG
    true_ketu_display = (true_rahu_display + 180.0) % 360.0
    lagna_display = lagna_raw + REFERENCE_LAGNA_DISPLAY_OFFSET_DEG

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

    sun_d9_rashi = _navamsa_rashi(sun_display)
    moon_d9_rashi = _navamsa_rashi(moon_display)
    lagna_d9_rashi = _navamsa_rashi(lagna_display)
    mars_d9_rashi = _navamsa_rashi(mars_display)
    mercury_d9_rashi = _navamsa_rashi(mercury_display)
    jupiter_d9_rashi = _navamsa_rashi(jupiter_display)
    venus_d9_rashi = _navamsa_rashi(venus_display)
    saturn_d9_rashi = _navamsa_rashi(saturn_display)
    mean_rahu_d9_rashi = _navamsa_rashi(mean_rahu_display)
    mean_ketu_d9_rashi = _navamsa_rashi(mean_ketu_display)
    true_rahu_d9_rashi = _navamsa_rashi(true_rahu_display)
    true_ketu_d9_rashi = _navamsa_rashi(true_ketu_display)

    sun_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=sun_d9_rashi)
    moon_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=moon_d9_rashi)
    lagna_d9_house = 1
    mangal_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=mars_d9_rashi)
    budha_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=mercury_d9_rashi)
    guru_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=jupiter_d9_rashi)
    shukra_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=venus_d9_rashi)
    shani_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=saturn_d9_rashi)
    rahu_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=mean_rahu_d9_rashi)
    ketu_d9_house = _house_from_lagna(lagna_rashi=lagna_d9_rashi, target_rashi=mean_ketu_d9_rashi)
    spashth_rahu_d9_house = _house_from_lagna(
        lagna_rashi=lagna_d9_rashi,
        target_rashi=true_rahu_d9_rashi,
    )
    spashth_ketu_d9_house = _house_from_lagna(
        lagna_rashi=lagna_d9_rashi,
        target_rashi=true_ketu_d9_rashi,
    )

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
            d9_rashi=sun_d9_rashi,
            d9_house=sun_d9_house,
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
            d9_rashi=moon_d9_rashi,
            d9_house=moon_d9_house,
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
            d9_rashi=mars_d9_rashi,
            d9_house=mangal_d9_house,
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
            d9_rashi=mercury_d9_rashi,
            d9_house=budha_d9_house,
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
            d9_rashi=jupiter_d9_rashi,
            d9_house=guru_d9_house,
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
            d9_rashi=venus_d9_rashi,
            d9_house=shukra_d9_house,
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
            d9_rashi=saturn_d9_rashi,
            d9_house=shani_d9_house,
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
            d9_rashi=mean_rahu_d9_rashi,
            d9_house=rahu_d9_house,
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
            d9_rashi=mean_ketu_d9_rashi,
            d9_house=ketu_d9_house,
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
            d9_rashi=true_rahu_d9_rashi,
            d9_house=spashth_rahu_d9_house,
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
            d9_rashi=true_ketu_d9_rashi,
            d9_house=spashth_ketu_d9_house,
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
            d9_rashi=lagna_d9_rashi,
            d9_house=lagna_d9_house,
            sun_degree=sun_display,
        ),
    }

    d1_chart = _build_divisional_chart(
        lagna_rashi=lagna_rashi,
        graha_table=graha_table,
        house_key="house",
        rashi_key="rashi",
    )
    d9_chart = _build_divisional_chart(
        lagna_rashi=lagna_d9_rashi,
        graha_table=graha_table,
        house_key="d9_house",
        rashi_key="d9_rashi",
    )

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
            "reference_display_offset_deg": REFERENCE_DISPLAY_OFFSET_DEG,
            "reference_lagna_display_offset_deg": REFERENCE_LAGNA_DISPLAY_OFFSET_DEG,
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
        "varga": {
            "d1": d1_chart,
            "d9": d9_chart,
        },
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


def _build_divisional_chart(
    *,
    lagna_rashi: str,
    graha_table: dict[str, dict[str, object]],
    house_key: str,
    rashi_key: str,
) -> dict[str, object]:
    lagna_internal = REFERENCE_ALIAS_TO_INTERNAL_RASHI.get(lagna_rashi, lagna_rashi)
    lagna_index = RASHI_NAMES.index(lagna_internal)
    houses: dict[str, dict[str, object]] = {}
    for house in range(1, 13):
        house_rashi_internal = RASHI_NAMES[(lagna_index + house - 1) % 12]
        house_rashi = REFERENCE_RASHI_ALIASES.get(house_rashi_internal, house_rashi_internal)
        houses[str(house)] = {
            "rashi": house_rashi,
            "occupants": [],
        }

    for key, row in graha_table.items():
        house = int(row[house_key])
        houses[str(house)]["occupants"].append(key)

    order_index = {key: idx for idx, key in enumerate(GRAHA_ORDER)}
    for house in houses.values():
        occupants = house["occupants"]
        if isinstance(occupants, list):
            occupants.sort(key=lambda key: order_index.get(str(key), 999))

    return {
        "lagna_rashi": lagna_rashi,
        "houses": houses,
    }


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


def _navamsa_rashi(degree: float) -> str:
    normalized_degree = degree % 360.0
    sign_index = int(normalized_degree // 30.0)
    offset_in_sign = normalized_degree % 30.0
    navamsa_index = int(offset_in_sign // (30.0 / 9.0))
    modality = sign_index % 3
    if modality == 0:
        start_index = sign_index
    elif modality == 1:
        start_index = (sign_index + 8) % 12
    else:
        start_index = (sign_index + 4) % 12
    navamsa_sign_index = (start_index + navamsa_index) % 12
    internal_name = RASHI_NAMES[navamsa_sign_index]
    return REFERENCE_RASHI_ALIASES.get(internal_name, internal_name)


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
    return REFERENCE_RASHI_ALIASES.get(internal_name, internal_name)


def _truncate_2(value: float) -> float:
    return trunc(value * 100.0) / 100.0


def _house_from_lagna(*, lagna_rashi: str, target_rashi: str) -> int:
    lagna_internal = REFERENCE_ALIAS_TO_INTERNAL_RASHI.get(lagna_rashi, lagna_rashi)
    target_internal = REFERENCE_ALIAS_TO_INTERNAL_RASHI.get(target_rashi, target_rashi)
    lagna_index = RASHI_NAMES.index(lagna_internal)
    target_index = RASHI_NAMES.index(target_internal)
    return ((target_index - lagna_index) % 12) + 1
