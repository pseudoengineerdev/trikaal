from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

import swisseph as swe

from vedic_engine.domain import BirthEvent, CalculationProfile


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

    return {
        "meta": {
            "status": "computed",
            "profile_id": profile.profile_id,
            "timezone": birth_event.timezone,
            "utc_iso": utc_dt.isoformat().replace("+00:00", "Z"),
        },
        "astronomy": {
            "julian_day_utc": round(julian_day_utc, 10),
            "sun_sidereal_deg": round(sun_data[0], 2),
            "moon_sidereal_deg": round(moon_data[0], 2),
            "sun_sidereal_deg_raw": round(sun_data[0], 8),
            "moon_sidereal_deg_raw": round(moon_data[0], 8),
        },
    }
