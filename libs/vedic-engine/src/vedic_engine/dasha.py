from __future__ import annotations

from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

import swisseph as swe

from vedic_engine.domain import BirthEvent, CalculationProfile

LORD_SEQUENCE_KEYS = [
    "ketu",
    "venus",
    "sun",
    "moon",
    "mars",
    "rahu",
    "jupiter",
    "saturn",
    "mercury",
]
LORD_LABELS = {
    "ketu": "Ketu",
    "venus": "Shukra",
    "sun": "Surya",
    "moon": "Chandra",
    "mars": "Mangal",
    "rahu": "Rahu",
    "jupiter": "Guru",
    "saturn": "Shani",
    "mercury": "Budha",
}
LORD_YEARS = {
    "ketu": 7.0,
    "venus": 20.0,
    "sun": 6.0,
    "moon": 10.0,
    "mars": 7.0,
    "rahu": 18.0,
    "jupiter": 16.0,
    "saturn": 19.0,
    "mercury": 17.0,
}
YEARS_IN_CYCLE = 120.0
NAKSHATRA_SPAN_DEG = 360.0 / 27.0
DAYS_PER_YEAR = 365.2425
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


def compute_vimshottari_dasha(
    *,
    birth_event: BirthEvent,
    profile: CalculationProfile,
    as_of: datetime | None = None,
) -> dict[str, object]:
    local_dt = datetime.strptime(
        f"{birth_event.local_date} {birth_event.local_time}",
        "%Y-%m-%d %H:%M",
    ).replace(tzinfo=ZoneInfo(birth_event.timezone))
    utc_dt = local_dt.astimezone(ZoneInfo("UTC"))
    as_of_local = as_of.astimezone(ZoneInfo(birth_event.timezone)) if as_of else datetime.now(
        ZoneInfo(birth_event.timezone)
    )

    if profile.ayanamsha == "lahiri_chitrapaksha":
        swe.set_sid_mode(swe.SIDM_LAHIRI)

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
    flags = swe.FLG_MOSEPH | swe.FLG_SIDEREAL | swe.FLG_SPEED
    moon_data, _ = swe.calc_ut(julian_day_utc, swe.MOON, flags)
    moon_sidereal_deg = moon_data[0] % 360.0

    nakshatra_index = int(moon_sidereal_deg // NAKSHATRA_SPAN_DEG)
    moon_nakshatra = NAKSHATRA_NAMES[nakshatra_index]
    nakshatra_progress = (moon_sidereal_deg % NAKSHATRA_SPAN_DEG) / NAKSHATRA_SPAN_DEG
    starting_lord = LORD_SEQUENCE_KEYS[nakshatra_index % len(LORD_SEQUENCE_KEYS)]
    starting_lord_years = LORD_YEARS[starting_lord]
    elapsed_in_starting_maha_years = starting_lord_years * nakshatra_progress
    start_of_starting_maha = local_dt - _years_to_timedelta(elapsed_in_starting_maha_years)

    current_maha = _find_current_maha(
        start_lord=starting_lord,
        start_of_starting_maha=start_of_starting_maha,
        as_of=as_of_local,
    )
    current_antar = _find_current_antar(
        maha_lord=current_maha["lord_key"],
        maha_start=current_maha["start"],
        as_of=as_of_local,
    )

    return {
        "system": "Vimshottari",
        "as_of_iso": as_of_local.isoformat(),
        "birth_moon_nakshatra": moon_nakshatra,
        "current_maha_dasha": LORD_LABELS[current_maha["lord_key"]],
        "current_antar_dasha": LORD_LABELS[current_antar["lord_key"]],
        "active_from": current_antar["start"].isoformat(),
        "active_until": current_antar["end"].isoformat(),
    }


def _find_current_maha(
    *,
    start_lord: str,
    start_of_starting_maha: datetime,
    as_of: datetime,
) -> dict[str, object]:
    sequence_index = LORD_SEQUENCE_KEYS.index(start_lord)
    current_start = start_of_starting_maha
    for _ in range(200):
        lord_key = LORD_SEQUENCE_KEYS[sequence_index]
        duration = _years_to_timedelta(LORD_YEARS[lord_key])
        current_end = current_start + duration
        if current_start <= as_of < current_end:
            return {
                "lord_key": lord_key,
                "start": current_start,
                "end": current_end,
            }
        current_start = current_end
        sequence_index = (sequence_index + 1) % len(LORD_SEQUENCE_KEYS)
    raise RuntimeError("Unable to determine current Mahadasha in bounded iteration.")


def _find_current_antar(
    *,
    maha_lord: str,
    maha_start: datetime,
    as_of: datetime,
) -> dict[str, object]:
    maha_years = LORD_YEARS[maha_lord]
    sequence_index = LORD_SEQUENCE_KEYS.index(maha_lord)
    current_start = maha_start
    for _ in range(40):
        antar_lord_key = LORD_SEQUENCE_KEYS[sequence_index]
        antar_years = (maha_years * LORD_YEARS[antar_lord_key]) / YEARS_IN_CYCLE
        current_end = current_start + _years_to_timedelta(antar_years)
        if current_start <= as_of < current_end:
            return {
                "lord_key": antar_lord_key,
                "start": current_start,
                "end": current_end,
            }
        current_start = current_end
        sequence_index = (sequence_index + 1) % len(LORD_SEQUENCE_KEYS)
    raise RuntimeError("Unable to determine current Antardasha in bounded iteration.")


def _years_to_timedelta(years: float) -> timedelta:
    return timedelta(days=years * DAYS_PER_YEAR)
