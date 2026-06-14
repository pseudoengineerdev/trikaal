"""Gochar (planetary transit) astronomy.

This module adds the *time-search* computations a transit feature needs and that
a single chart snapshot cannot give: when a planet entered (and will leave) its
current sign, when it next stations (turns retrograde/direct), and the Sade Sati
/ Dhaiya windows of Saturn relative to the natal Moon.

It deliberately reuses the engine-wide conventions from :mod:`calculator`
(Moshier ephemeris, Lahiri sidereal, the 0.01° display offset) so that every
sign boundary it reports matches the rashi that :func:`compute_chart_snapshot`
would print for the same instant. The instantaneous positions themselves are
still taken from the snapshot — this module only answers the "*when*" questions.

Ashtakavarga (the advanced transit-strength layer) is delegated to ``pyjhora``,
the same library the calculator already uses for divisional charts, so the
classical bindu tables are never hand-transcribed here.
"""

from __future__ import annotations

import contextlib
import importlib
import io
from datetime import datetime, timedelta
from functools import lru_cache
from zoneinfo import ZoneInfo

import swisseph as swe

from vedic_engine.calculator import (
    REFERENCE_ALIAS_TO_INTERNAL_RASHI,
    REFERENCE_DISPLAY_OFFSET_DEG,
    RASHI_NAMES,
)

_FLAGS = swe.FLG_MOSEPH | swe.FLG_SIDEREAL | swe.FLG_SPEED

# swisseph body id per engine graha key. Ketu is derived from the mean node.
_SWE_BODY_BY_KEY: dict[str, int] = {
    "sun": swe.SUN,
    "moon": swe.MOON,
    "mangal": swe.MARS,
    "budha": swe.MERCURY,
    "guru": swe.JUPITER,
    "shukra": swe.VENUS,
    "shani": swe.SATURN,
    "rahu": swe.MEAN_NODE,
    "ketu": swe.MEAN_NODE,
}

# Sun and Moon never retrograde; the mean nodes are perpetually retrograde.
_NEVER_RETROGRADE = frozenset({"sun", "moon"})
_ALWAYS_RETROGRADE = frozenset({"rahu", "ketu"})

# Coarse scan step (in days) per graha for sign-change / station searches. Kept
# well below the distance the body covers in one sign so a scan can never skip a
# whole sign, while staying cheap for the slow movers.
_SCAN_STEP_DAYS: dict[str, float] = {
    "sun": 0.5,
    "moon": 0.05,
    "mangal": 0.5,
    "budha": 0.25,
    "guru": 1.5,
    "shukra": 0.5,
    "shani": 2.0,
    "rahu": 2.0,
    "ketu": 2.0,
}

# How far a search will look before giving up (days).
_SIGN_HORIZON_DAYS: dict[str, float] = {
    "sun": 80.0,
    "moon": 6.0,
    "mangal": 900.0,
    "budha": 120.0,
    "guru": 600.0,
    "shukra": 400.0,
    # Saturn's horizon must cover the full ~7.5y, 3-sign Sade Sati band, not just
    # a single ~2.5y sign occupancy.
    "shani": 3000.0,
    "rahu": 800.0,
    "ketu": 800.0,
}

# A retrograde body can leave a sign, dip back, and re-enter near a station;
# such an excursion is absorbed so one occupancy reads as a single window. The
# gap must sit above the body's retrograde duration but well below the time
# before it *legitimately* re-occupies the sign as a fresh transit — otherwise
# (e.g. the Moon returning every ~27 days) separate transits would be merged.
# The Sun, Moon and mean nodes move monotonically through the signs, so they
# never need merging.
_MERGE_GAP_DAYS: dict[str, float] = {
    "sun": 0.0,
    "moon": 0.0,
    "mangal": 90.0,
    "budha": 35.0,
    "shukra": 55.0,
    "guru": 160.0,
    "shani": 175.0,
    "rahu": 0.0,
    "ketu": 0.0,
}

# |speed| below this (deg/day) is reported as a station rather than direct/retro.
_STATIONARY_EPS = 0.003

# Search window for the next/previous station (days). Mars has the longest
# direct-then-retrograde synodic cycle of the five retrograde-capable grahas
# (~25 months), so this single horizon safely brackets a station for all of
# them with margin; the others (Mercury..Saturn) reverse far more often.
_STATION_HORIZON_DAYS = 900.0

_MINUTE_JD = 1.0 / (24.0 * 60.0)


# --------------------------------------------------------------------------- #
# Julian-day helpers (kept in sync with calculator's conventions)
# --------------------------------------------------------------------------- #
def julian_day_from_utc(utc_dt: datetime) -> float:
    """Julian day (UT) for an aware UTC datetime."""
    hours = (
        utc_dt.hour
        + (utc_dt.minute / 60.0)
        + (utc_dt.second / 3600.0)
        + (utc_dt.microsecond / 3_600_000_000.0)
    )
    return swe.julday(utc_dt.year, utc_dt.month, utc_dt.day, hours, swe.GREG_CAL)


def jd_to_utc(jd: float) -> datetime:
    """Aware UTC datetime for a Julian day (UT)."""
    year, month, day, hour = swe.revjul(jd, swe.GREG_CAL)
    midnight = datetime(year, month, day, tzinfo=ZoneInfo("UTC"))
    return midnight + timedelta(hours=hour)


# --------------------------------------------------------------------------- #
# Instantaneous position / motion
# --------------------------------------------------------------------------- #
def sidereal_longitude(jd: float, key: str) -> float:
    """Display sidereal longitude (deg, 0..360) for ``key`` at ``jd``.

    Matches the value :func:`compute_chart_snapshot` derives the rashi from, so
    ``int(sidereal_longitude(jd, key) // 30)`` is the same sign index the
    snapshot would report.
    """
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    body = _SWE_BODY_BY_KEY[key]
    data, _ = swe.calc_ut(jd, body, _FLAGS)
    longitude = data[0]
    if key == "ketu":
        longitude = (longitude + 180.0) % 360.0
    return (longitude - REFERENCE_DISPLAY_OFFSET_DEG) % 360.0


def sign_index(jd: float, key: str) -> int:
    """Sign index 0..11 (0 = Mesh / Aries) for ``key`` at ``jd``."""
    return int(sidereal_longitude(jd, key) // 30.0)


def longitude_speed(jd: float, key: str) -> float:
    """Longitudinal speed (deg/day) for ``key`` at ``jd``.

    Ketu deliberately returns the mean node's speed unchanged: Ketu's longitude
    is the mean node's plus a *constant* 180°, so its rate of change is identical
    — both nodes move retrograde at the same speed. (Do not negate it.)
    """
    swe.set_sid_mode(swe.SIDM_LAHIRI)
    data, _ = swe.calc_ut(jd, _SWE_BODY_BY_KEY[key], _FLAGS)
    return data[3]


def motion_state(jd: float, key: str) -> str:
    """One of ``"direct"``, ``"retrograde"`` or ``"stationary"``."""
    if key in _ALWAYS_RETROGRADE:
        return "retrograde"
    if key in _NEVER_RETROGRADE:
        return "direct"
    speed = longitude_speed(jd, key)
    if abs(speed) < _STATIONARY_EPS:
        return "stationary"
    return "retrograde" if speed < 0 else "direct"


# --------------------------------------------------------------------------- #
# Sign-occupancy window (entered / leaves current sign)
# --------------------------------------------------------------------------- #
def sign_occupancy_window(jd: float, key: str) -> tuple[float | None, float | None]:
    """``(entry_jd, exit_jd)`` of the current-sign occupancy bracketing ``jd``.

    ``entry_jd`` is when the body last entered its current sign; ``exit_jd`` when
    it next leaves. Brief retrograde excursions out of the sign (shorter than the
    merge gap) are absorbed so the window reflects the real, continuous stay.
    Either side is ``None`` if no boundary is found within the search horizon
    (e.g. the Moon, whose nakshatra-fine window we never need that far out).
    """
    current = sign_index(jd, key)
    entry = _find_band_edge(jd, key, {current}, direction=-1)
    exit_jd = _find_band_edge(jd, key, {current}, direction=+1)
    return entry, exit_jd


def _find_band_edge(
    jd: float,
    key: str,
    band: set[int],
    *,
    direction: int,
) -> float | None:
    """Find the boundary where ``key`` enters/leaves ``band`` around ``jd``.

    Walks ``direction`` (+1 forward, -1 backward) in coarse steps while the body
    stays in ``band``, tolerating excursions shorter than the merge gap, then
    bisects the final crossing to the minute. Returns the crossing JD, or
    ``None`` if the body stays in band to the horizon.
    """
    step = _SCAN_STEP_DAYS[key] * direction
    horizon = _SIGN_HORIZON_DAYS[key]

    last_in_band = jd
    probe = jd
    travelled = 0.0
    while travelled <= horizon:
        probe += step
        travelled += abs(step)
        if sign_index(probe, key) in band:
            last_in_band = probe
            continue
        # Left the band — see whether it returns within the merge gap.
        if _returns_to_band(probe, key, band, direction):
            continue
        # Genuine exit: bisect between the last in-band probe and this one.
        lo, hi = (last_in_band, probe) if direction > 0 else (probe, last_in_band)
        return _bisect_band_crossing(lo, hi, key, band)
    return None


def _returns_to_band(
    probe: float,
    key: str,
    band: set[int],
    direction: int,
) -> bool:
    """Whether the body re-enters ``band`` within the merge gap of ``probe``."""
    merge_gap = _MERGE_GAP_DAYS[key]
    if merge_gap <= 0.0:
        return False
    step = _SCAN_STEP_DAYS[key] * direction
    inner = probe
    travelled = 0.0
    while travelled <= merge_gap:
        inner += step
        travelled += abs(step)
        if sign_index(inner, key) in band:
            return True
    return False


def _bisect_band_crossing(a: float, b: float, key: str, band: set[int]) -> float:
    """Refine a single band crossing bracketed by ``a`` and ``b`` to ~1 minute.

    Order-agnostic: exactly one of the two ends is in band; ``a`` is held on its
    starting side and walked toward the boundary, so this is correct whether the
    caller passes the in-band end first (forward exit) or last (backward entry).
    """
    a_in_band = sign_index(a, key) in band
    for _ in range(64):
        if abs(b - a) <= _MINUTE_JD:
            break
        mid = (a + b) / 2.0
        if (sign_index(mid, key) in band) == a_in_band:
            a = mid
        else:
            b = mid
    return (a + b) / 2.0


# --------------------------------------------------------------------------- #
# Retrograde stations
# --------------------------------------------------------------------------- #
def next_station(jd: float, key: str) -> float | None:
    """JD of the next motion reversal (direct<->retrograde) after ``jd``.

    Searches up to ``_STATION_HORIZON_DAYS``; returns ``None`` for the Sun, Moon
    and nodes (which never station) or if no reversal is found in that window.
    """
    return _find_station(jd, key, direction=+1)


def previous_station(jd: float, key: str) -> float | None:
    """JD of the most recent motion reversal before ``jd`` (see :func:`next_station`)."""
    return _find_station(jd, key, direction=-1)


def _find_station(jd: float, key: str, *, direction: int) -> float | None:
    if key in _NEVER_RETROGRADE or key in _ALWAYS_RETROGRADE:
        return None
    step = 2.0 * direction
    horizon = _STATION_HORIZON_DAYS
    start_sign = 1 if longitude_speed(jd, key) >= 0 else -1

    probe = jd
    travelled = 0.0
    last = jd
    while travelled <= horizon:
        probe += step
        travelled += abs(step)
        speed = longitude_speed(probe, key)
        sign = 1 if speed >= 0 else -1
        if sign != start_sign:
            lo, hi = (last, probe) if direction > 0 else (probe, last)
            return _bisect_station(lo, hi, key)
        last = probe
    return None


def _bisect_station(lo: float, hi: float, key: str) -> float:
    """Refine a speed sign-change (station) to ~1 minute."""
    lo_sign = 1 if longitude_speed(lo, key) >= 0 else -1
    for _ in range(64):
        if (hi - lo) <= _MINUTE_JD:
            break
        mid = (lo + hi) / 2.0
        mid_sign = 1 if longitude_speed(mid, key) >= 0 else -1
        if mid_sign == lo_sign:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2.0


# --------------------------------------------------------------------------- #
# Saturn: Sade Sati and Dhaiya windows relative to the natal Moon
# --------------------------------------------------------------------------- #
def saturn_relative_house(jd: float, natal_moon_sign_index: int) -> int:
    """House (1..12) of transiting Saturn counted from the natal Moon sign."""
    saturn_sign = sign_index(jd, "shani")
    return ((saturn_sign - natal_moon_sign_index) % 12) + 1


def saturn_band_window(
    jd: float,
    natal_moon_sign_index: int,
    houses_from_moon: set[int],
) -> tuple[float | None, float | None]:
    """``(start_jd, end_jd)`` of Saturn's contiguous stay across the given
    houses-from-Moon band bracketing ``jd``, or ``(None, None)`` when Saturn is
    not currently in that band.

    Used for both the 3-sign Sade Sati band ``{12, 1, 2}`` and the single-sign
    Dhaiya houses ``{4}`` / ``{8}``.
    """
    band_signs = {
        (natal_moon_sign_index + house - 1) % 12 for house in houses_from_moon
    }
    if sign_index(jd, "shani") not in band_signs:
        return None, None
    start = _find_band_edge(jd, "shani", band_signs, direction=-1)
    end = _find_band_edge(jd, "shani", band_signs, direction=+1)
    return start, end


def next_band_entry(
    jd: float,
    key: str,
    band: set[int],
    *,
    horizon_days: float = 12000.0,
) -> float | None:
    """JD when ``key`` next enters one of the ``band`` signs strictly after ``jd``.

    Assumes ``key`` is currently outside ``band``. Used both to announce the next
    Sade Sati and to find the start of each Sade Sati leg (a single-sign band).
    """
    step = _SCAN_STEP_DAYS[key]
    probe = jd
    travelled = 0.0
    last = jd
    while travelled <= horizon_days:
        probe += step
        travelled += step
        if sign_index(probe, key) in band:
            return _bisect_band_crossing(probe, last, key, band)
        last = probe
    return None


def next_saturn_band_entry(
    jd: float,
    natal_moon_sign_index: int,
    houses_from_moon: set[int],
) -> float | None:
    """JD when Saturn next enters the given houses-from-Moon band after ``jd``
    (used to announce the next Sade Sati when one is not currently running)."""
    band_signs = {
        (natal_moon_sign_index + house - 1) % 12 for house in houses_from_moon
    }
    return next_band_entry(jd, "shani", band_signs)


# --------------------------------------------------------------------------- #
# Ashtakavarga (transit strength) via pyjhora
# --------------------------------------------------------------------------- #
# pyjhora planet ids: 0 Sun .. 6 Saturn, 7 Rahu, 8 Ketu, "L" Lagnam.
_JHORA_ID_BY_KEY: dict[str, str] = {
    "sun": "0",
    "moon": "1",
    "mangal": "2",
    "budha": "3",
    "guru": "4",
    "shukra": "5",
    "shani": "6",
    "rahu": "7",
    "ketu": "8",
    "lagna": "L",
}
# Bodies that own a Bhinnashtakavarga (the nodes do not).
_BAV_KEYS = ("sun", "moon", "mangal", "budha", "guru", "shukra", "shani")


@lru_cache(maxsize=1)
def _load_jhora_ashtakavarga_module():
    try:
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(
            io.StringIO()
        ):
            return importlib.import_module("jhora.horoscope.chart.ashtakavarga")
    except Exception as exc:  # pragma: no cover - exercised via integration tests
        raise RuntimeError(
            "Ashtakavarga computation requires pyjhora to be installed and importable."
        ) from exc


def compute_ashtakavarga(rashi_index_by_key: dict[str, int]) -> dict[str, object]:
    """Natal Ashtakavarga from sign indices keyed by graha.

    ``rashi_index_by_key`` must contain sign indices (0 = Aries .. 11 = Pisces)
    for sun, moon, mangal, budha, guru, shukra, shani, rahu, ketu and lagna.

    Returns ``{"bav": {graha: [12 bindus]}, "sav": [12 bindus]}`` where each list
    is indexed by sign (0 = Aries). ``bav`` covers the seven classical planets;
    ``sav`` is the Sarvashtakavarga (per-sign total over those seven).
    """
    module = _load_jhora_ashtakavarga_module()

    house_to_planets: list[list[str]] = [[] for _ in range(12)]
    for key, jhora_id in _JHORA_ID_BY_KEY.items():
        if key not in rashi_index_by_key:
            raise ValueError(f"compute_ashtakavarga missing sign index for {key!r}")
        house_to_planets[rashi_index_by_key[key] % 12].append(jhora_id)
    chart = ["/".join(planets) for planets in house_to_planets]

    bav_matrix, sav, _prastara = module.get_ashtaka_varga(chart)

    bav = {
        key: [int(value) for value in bav_matrix[index]]
        for index, key in enumerate(_BAV_KEYS)
    }
    return {"bav": bav, "sav": [int(value) for value in sav]}


# --------------------------------------------------------------------------- #
# Small shared helpers for callers (API layer)
# --------------------------------------------------------------------------- #
def sign_index_from_rashi_name(rashi: str) -> int:
    """Sign index 0..11 for an internal or reference rashi name."""
    internal = REFERENCE_ALIAS_TO_INTERNAL_RASHI.get(rashi, rashi)
    return RASHI_NAMES.index(internal)
