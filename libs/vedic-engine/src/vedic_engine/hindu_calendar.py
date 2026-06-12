from __future__ import annotations

from calendar import monthrange
from dataclasses import dataclass
import math
from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

import swisseph as swe

from vedic_engine.calculator import (
    REFERENCE_DISPLAY_OFFSET_DEG,
    TITHI_NAMES_ENGLISH,
    TITHI_NAMES_VEDIC,
)
from vedic_engine.dasha import NAKSHATRA_NAMES, NAKSHATRA_SPAN_DEG

_LUNAR_MONTH_NAMES = (
    "Chaitra",
    "Vaishakha",
    "Jyeshtha",
    "Ashadha",
    "Shravana",
    "Bhadrapada",
    "Ashwin",
    "Kartika",
    "Margashirsha",
    "Pausha",
    "Magha",
    "Phalguna",
)

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

_WEEKDAY_NAMES = (
    "Sunday",
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
)

_MONTH_TYPES = {"amanta", "purnimanta"}
_PLANETARY_FLAGS = swe.FLG_MOSEPH | swe.FLG_SIDEREAL | swe.FLG_SPEED
_PHASE_BOUNDARY_EPSILON_DAYS = 1e-4


@dataclass(frozen=True)
class _AmantaMonthInfo:
    name: str
    is_adhika: bool


def compute_hindu_calendar_month(
    *,
    year: int,
    month: int,
    timezone: str,
    latitude: float,
    longitude: float,
    elevation_m: float,
    month_type: str = "purnimanta",
) -> dict[str, object]:
    """Compute a Vedic lunar calendar month for a location."""
    if month_type not in _MONTH_TYPES:
        raise ValueError(f"Unsupported month_type: {month_type}")
    if month < 1 or month > 12:
        raise ValueError(f"month must be between 1 and 12, received {month}")

    tz = ZoneInfo(timezone)
    first_date = date(year, month, 1)
    _, day_count = monthrange(year, month)
    first_weekday_sunday0 = (first_date.weekday() + 1) % 7

    days: list[dict[str, object]] = []
    for day in range(1, day_count + 1):
        current_date = date(year, month, day)
        sunrise_event = _compute_sun_event_jd(
            current_date=current_date,
            timezone=timezone,
            latitude=latitude,
            longitude=longitude,
            elevation_m=elevation_m,
            event_flag=swe.CALC_RISE,
        )
        sunset_event = _compute_sun_event_jd(
            current_date=current_date,
            timezone=timezone,
            latitude=latitude,
            longitude=longitude,
            elevation_m=elevation_m,
            event_flag=swe.CALC_SET,
        )
        if sunrise_event is None:
            # Polar day/night: anchor the panchang at local noon instead.
            sunrise_utc = None
            sunrise_local = None
            anchor_jd = _jd_at_local_hour(current_date, timezone, hour=12.0)
        else:
            sunrise_utc, sunrise_local, anchor_jd = sunrise_event
        sunset_local = sunset_event[1] if sunset_event is not None else None
        sun_deg, moon_deg = _sun_moon_sidereal_degrees(anchor_jd)
        nakshatra_index = int((moon_deg % 360.0) // NAKSHATRA_SPAN_DEG)
        tithi_phase = (moon_deg - sun_deg) % 360.0
        tithi_number = int(tithi_phase // 12.0) + 1
        paksha = "Shukla" if tithi_number <= 15 else "Krishna"
        tithi_day = ((tithi_number - 1) % 15) + 1
        tithi_name_vedic = TITHI_NAMES_VEDIC[tithi_number - 1]
        tithi_name_english = TITHI_NAMES_ENGLISH[tithi_number - 1]
        weekday_index_sunday0 = (current_date.weekday() + 1) % 7

        amanta_month = _amanta_lunar_month_info(anchor_jd)
        if month_type == "amanta":
            lunar_month_name = _format_lunar_month_name(amanta_month)
            lunar_day_of_month = tithi_number
        elif amanta_month.is_adhika:
            lunar_month_name = _format_lunar_month_name(amanta_month)
            lunar_day_of_month = (
                tithi_day if paksha == "Shukla" else tithi_day + 15
            )
        elif paksha == "Krishna":
            lunar_month_name = _next_lunar_month_name(amanta_month.name)
            lunar_day_of_month = tithi_day
        else:
            lunar_month_name = amanta_month.name
            lunar_day_of_month = tithi_day + 15

        days.append(
            {
                "gregorian_date": current_date.isoformat(),
                "day": day,
                "weekday_index_sunday0": weekday_index_sunday0,
                "weekday_name": _WEEKDAY_NAMES[weekday_index_sunday0],
                "sunrise_local_time": (
                    sunrise_local.strftime("%H:%M") if sunrise_local else ""
                ),
                "sunrise_local_iso": (
                    sunrise_local.isoformat() if sunrise_local else ""
                ),
                "sunrise_utc_iso": (
                    sunrise_utc.isoformat().replace("+00:00", "Z")
                    if sunrise_utc
                    else ""
                ),
                "sunset_local_time": (
                    sunset_local.strftime("%H:%M") if sunset_local else ""
                ),
                "lunar_month_name": lunar_month_name,
                "lunar_day_of_month": lunar_day_of_month,
                "paksha": paksha,
                "paksha_english": "Waxing" if paksha == "Shukla" else "Waning",
                "tithi_number": tithi_number,
                "tithi_day": tithi_day,
                "tithi_name_vedic": tithi_name_vedic,
                "tithi_name_english": tithi_name_english,
                "sun_sidereal_deg": round(sun_deg, 4),
                "moon_sidereal_deg": round(moon_deg, 4),
                "sun_rashi": _sidereal_rashi_name(sun_deg),
                "moon_rashi": _sidereal_rashi_name(moon_deg),
                "nakshatra_number": nakshatra_index + 1,
                "nakshatra_name": NAKSHATRA_NAMES[nakshatra_index],
            }
        )

    today_local = datetime.now(tz).date()
    selected_date = (
        today_local
        if today_local.year == year and today_local.month == month
        else first_date
    )
    selected_iso = selected_date.isoformat()
    selected_day = next(
        (day_entry for day_entry in days if day_entry["gregorian_date"] == selected_iso),
        days[0],
    )

    lunar_months_in_view = list(
        dict.fromkeys(str(day_entry["lunar_month_name"]) for day_entry in days)
    )

    return {
        "calendar_profile_id": "vedic_hindu_calendar_v1",
        "month_type": month_type,
        "year": year,
        "month": month,
        "gregorian_month_label": first_date.strftime("%B %Y"),
        "first_weekday_sunday0": first_weekday_sunday0,
        "day_count": day_count,
        "timezone": timezone,
        "today_local_date": today_local.isoformat(),
        "selected_date": selected_iso,
        "selected_day": selected_day,
        "lunar_months_in_view": lunar_months_in_view,
        "days": days,
    }


def _jd_at_local_hour(current_date: date, timezone: str, *, hour: float) -> float:
    local_moment = datetime(
        current_date.year,
        current_date.month,
        current_date.day,
        tzinfo=ZoneInfo(timezone),
    ) + timedelta(hours=hour)
    utc_moment = local_moment.astimezone(ZoneInfo("UTC"))
    utc_hours = (
        utc_moment.hour
        + (utc_moment.minute / 60.0)
        + (utc_moment.second / 3600.0)
        + (utc_moment.microsecond / 3_600_000_000.0)
    )
    return swe.julday(
        utc_moment.year,
        utc_moment.month,
        utc_moment.day,
        utc_hours,
        swe.GREG_CAL,
    )


def _compute_sun_event_jd(
    *,
    current_date: date,
    timezone: str,
    latitude: float,
    longitude: float,
    elevation_m: float,
    event_flag: int,
) -> tuple[datetime, datetime, float] | None:
    jd_utc = _jd_at_local_hour(current_date, timezone, hour=0.0)
    # Traditional Hindu sunrise: solar disc center, no atmospheric refraction.
    result, tret = swe.rise_trans(
        jd_utc,
        swe.SUN,
        event_flag | swe.BIT_DISC_CENTER | swe.BIT_NO_REFRACTION,
        (longitude, latitude, elevation_m),
        0.0,
        15.0,
        swe.FLG_SWIEPH,
    )
    if result != 0:
        # Circumpolar date: the sun never crosses the horizon.
        return None
    event_utc = _jd_to_utc_datetime(tret[0])
    event_local = event_utc.astimezone(ZoneInfo(timezone))
    return event_utc, event_local, tret[0]


def _sun_moon_sidereal_degrees(julian_day_utc: float) -> tuple[float, float]:
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    sun_data, _ = swe.calc_ut(julian_day_utc, swe.SUN, _PLANETARY_FLAGS)
    moon_data, _ = swe.calc_ut(julian_day_utc, swe.MOON, _PLANETARY_FLAGS)
    sun_deg = (sun_data[0] - REFERENCE_DISPLAY_OFFSET_DEG) % 360.0
    moon_deg = (moon_data[0] - REFERENCE_DISPLAY_OFFSET_DEG) % 360.0
    return sun_deg, moon_deg


def _amanta_lunar_month_info(julian_day_utc: float) -> _AmantaMonthInfo:
    previous_new_moon_jd = _find_previous_new_moon_jd(julian_day_utc)
    next_new_moon_jd = _find_next_new_moon_jd(julian_day_utc)
    start_rashi = _sidereal_sun_rashi_index(
        previous_new_moon_jd + _PHASE_BOUNDARY_EPSILON_DAYS
    )
    end_rashi = _sidereal_sun_rashi_index(
        next_new_moon_jd - _PHASE_BOUNDARY_EPSILON_DAYS
    )

    if start_rashi == end_rashi:
        return _AmantaMonthInfo(
            name=_next_lunar_month_name(_LUNAR_MONTH_NAMES[end_rashi]),
            is_adhika=True,
        )
    return _AmantaMonthInfo(name=_LUNAR_MONTH_NAMES[end_rashi], is_adhika=False)


def _format_lunar_month_name(month: _AmantaMonthInfo) -> str:
    if month.is_adhika:
        return f"{month.name} (Adhika)"
    return month.name


def _next_lunar_month_name(month_name: str) -> str:
    index = _LUNAR_MONTH_NAMES.index(month_name)
    return _LUNAR_MONTH_NAMES[(index + 1) % 12]


def _find_next_new_moon_jd(julian_day_utc: float) -> float:
    return _find_next_phase_jd(julian_day_utc, target_phase=0.0)


def _find_previous_new_moon_jd(julian_day_utc: float) -> float:
    return _find_previous_phase_jd(julian_day_utc, target_phase=0.0)


def _find_previous_phase_jd(julian_day_utc: float, *, target_phase: float) -> float:
    search_start_jd = julian_day_utc - 35.0
    candidate_jd = _find_next_phase_jd(
        search_start_jd,
        target_phase=target_phase,
        strict_floor=search_start_jd,
    )
    previous_jd = candidate_jd

    for _ in range(4):
        next_candidate_jd = _find_next_phase_jd(
            previous_jd + 1.0,
            target_phase=target_phase,
            strict_floor=previous_jd + 1.0,
        )
        if next_candidate_jd >= julian_day_utc - _PHASE_BOUNDARY_EPSILON_DAYS:
            return previous_jd
        previous_jd = next_candidate_jd

    return previous_jd


def _find_next_phase_jd(
    julian_day_utc: float,
    *,
    target_phase: float,
    strict_floor: float | None = None,
) -> float:
    phase_prev = _lunar_phase_deg(julian_day_utc)
    unwrapped_prev = phase_prev
    jd_prev = julian_day_utc
    step_days = 0.5

    target = float(target_phase) % 360.0
    target_unwrapped = _next_unwrapped_phase_mark(unwrapped_prev, target)

    for step in range(1, 120):
        jd_current = julian_day_utc + (step * step_days)
        phase_current = _lunar_phase_deg(jd_current)
        delta = phase_current - phase_prev
        if delta < -180.0:
            delta += 360.0
        elif delta > 180.0:
            delta -= 360.0
        unwrapped_current = unwrapped_prev + delta

        if unwrapped_prev <= target_unwrapped <= unwrapped_current:
            ratio = (
                (target_unwrapped - unwrapped_prev) / (unwrapped_current - unwrapped_prev)
                if unwrapped_current != unwrapped_prev
                else 0.0
            )
            estimate = jd_prev + ((jd_current - jd_prev) * ratio)
            return _refine_phase_jd(
                estimate,
                floor_jd=(
                    strict_floor
                    if strict_floor is not None
                    else julian_day_utc
                ),
                target_phase=target,
            )

        jd_prev = jd_current
        phase_prev = phase_current
        unwrapped_prev = unwrapped_current

    raise RuntimeError("Unable to locate requested lunar phase within 60 days.")


def _next_unwrapped_phase_mark(unwrapped_phase: float, target_phase: float) -> float:
    base = math.floor(unwrapped_phase / 360.0) * 360.0
    target = base + target_phase
    if target <= unwrapped_phase:
        target += 360.0
    return target


def _refine_phase_jd(
    estimate_jd: float,
    *,
    floor_jd: float,
    target_phase: float,
) -> float:
    jd = max(estimate_jd, floor_jd)
    for _ in range(8):
        phase = _lunar_phase_deg(jd)
        error = (phase - target_phase) % 360.0
        if error > 180.0:
            error -= 360.0
        if abs(error) < 1e-7:
            return jd

        swe.set_sid_mode(swe.SIDM_LAHIRI)
        sun_data, _ = swe.calc_ut(jd, swe.SUN, _PLANETARY_FLAGS)
        moon_data, _ = swe.calc_ut(jd, swe.MOON, _PLANETARY_FLAGS)
        speed = moon_data[3] - sun_data[3]
        if abs(speed) < 1e-7:
            break
        jd -= error / speed
        if jd < floor_jd:
            jd = floor_jd

    return jd


def _sidereal_sun_rashi_index(julian_day_utc: float) -> int:
    sun_deg, _ = _sun_moon_sidereal_degrees(julian_day_utc)
    return int((sun_deg % 360.0) // 30.0)


def _lunar_phase_deg(julian_day_utc: float) -> float:
    sun_deg, moon_deg = _sun_moon_sidereal_degrees(julian_day_utc)
    return (moon_deg - sun_deg) % 360.0


def _sidereal_rashi_name(degree: float) -> str:
    index = int((degree % 360.0) // 30.0)
    return _SIDEREAL_RASHI_NAMES[index]


def _jd_to_utc_datetime(jd_utc: float) -> datetime:
    year, month, day, hour = swe.revjul(jd_utc, swe.GREG_CAL)
    midnight_utc = datetime(year, month, day, tzinfo=ZoneInfo("UTC"))
    return midnight_utc + timedelta(hours=hour)
