from __future__ import annotations

from datetime import datetime
from zoneinfo import ZoneInfo

from vedic_engine import BirthEvent, CalculationProfile, compute_chart_snapshot
from vedic_engine import gochar


def _transit_jd() -> float:
    """A fixed transit instant (2026-06-14 12:00 IST) for deterministic tests."""
    utc = datetime(2026, 6, 14, 12, 0, tzinfo=ZoneInfo("Asia/Kolkata")).astimezone(
        ZoneInfo("UTC")
    )
    return gochar.julian_day_from_utc(utc)


def _natal_sign_indices(birth_event: BirthEvent) -> dict[str, int]:
    snapshot = compute_chart_snapshot(
        birth_event=birth_event, profile=CalculationProfile()
    )
    graha_table = snapshot["graha_table"]
    return {
        key: gochar.sign_index_from_rashi_name(graha_table[key]["rashi"])
        for key in (
            "sun",
            "moon",
            "mangal",
            "budha",
            "guru",
            "shukra",
            "shani",
            "rahu",
            "ketu",
            "lagna",
        )
    }


# --------------------------------------------------------------------------- #
# Ashtakavarga invariants (the classical totals are a strong correctness check)
# --------------------------------------------------------------------------- #
def test_ashtakavarga_satisfies_classical_invariants() -> None:
    charts = [
        BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.07,
            longitude=72.87,
            elevation_m=0.0,
            place_label="Mumbai",
        ),
        BirthEvent(
            local_date="1985-01-15",
            local_time="06:30",
            timezone="Asia/Kolkata",
            latitude=28.6,
            longitude=77.2,
            elevation_m=0.0,
            place_label="Delhi",
        ),
    ]
    expected_bav_totals = {
        "sun": 48,
        "moon": 49,
        "mangal": 39,
        "budha": 54,
        "guru": 56,
        "shukra": 52,
        "shani": 39,
    }
    for birth_event in charts:
        result = gochar.compute_ashtakavarga(_natal_sign_indices(birth_event))
        for key, expected in expected_bav_totals.items():
            assert sum(result["bav"][key]) == expected, key
        assert sum(result["sav"]) == 337
        assert len(result["sav"]) == 12
        # Each sign's SAV equals the column sum across the seven BAVs.
        for sign in range(12):
            assert result["sav"][sign] == sum(
                result["bav"][key][sign] for key in expected_bav_totals
            )


def test_ashtakavarga_requires_all_keys() -> None:
    import pytest

    with pytest.raises(ValueError):
        gochar.compute_ashtakavarga({"sun": 0})


# --------------------------------------------------------------------------- #
# Sign-occupancy windows
# --------------------------------------------------------------------------- #
def test_sign_occupancy_window_brackets_current_sign() -> None:
    jd = _transit_jd()
    for key in ("sun", "moon", "mangal", "shani", "rahu"):
        current = gochar.sign_index(jd, key)
        entry, exit_jd = gochar.sign_occupancy_window(jd, key)
        assert entry is not None and exit_jd is not None, key
        assert entry < jd < exit_jd, key
        # The midpoint of the window is in the current sign...
        assert gochar.sign_index((entry + exit_jd) / 2.0, key) == current, key
        # ...and the body sits in a different sign just outside either edge.
        assert gochar.sign_index(entry - 0.02, key) != current, key
        assert gochar.sign_index(exit_jd + 0.02, key) != current, key


def test_sun_ingress_matches_snapshot_rashi() -> None:
    """The Sun's reported sign-entry instant must itself fall on the boundary the
    snapshot draws: one minute after entry the snapshot rashi is the new sign."""
    jd = _transit_jd()
    entry, _ = gochar.sign_occupancy_window(jd, "sun")
    assert entry is not None
    before = gochar.sign_index(entry - gochar._MINUTE_JD * 2, "sun")
    after = gochar.sign_index(entry + gochar._MINUTE_JD * 2, "sun")
    assert (after - before) % 12 == 1


# --------------------------------------------------------------------------- #
# Motion / stations
# --------------------------------------------------------------------------- #
def test_motion_state_for_luminaries_and_nodes() -> None:
    jd = _transit_jd()
    assert gochar.motion_state(jd, "sun") == "direct"
    assert gochar.motion_state(jd, "moon") == "direct"
    assert gochar.motion_state(jd, "rahu") == "retrograde"
    assert gochar.motion_state(jd, "ketu") == "retrograde"
    assert gochar.next_station(jd, "sun") is None
    assert gochar.next_station(jd, "rahu") is None


def test_next_station_flips_motion() -> None:
    jd = _transit_jd()
    for key in ("budha", "shukra", "mangal", "guru", "shani"):
        station = gochar.next_station(jd, key)
        assert station is not None, key
        before = gochar.longitude_speed(station - 0.5, key)
        after = gochar.longitude_speed(station + 0.5, key)
        # Speed changes sign across a genuine station.
        assert (before < 0) != (after < 0), key


# --------------------------------------------------------------------------- #
# Saturn windows relative to the natal Moon
# --------------------------------------------------------------------------- #
def test_saturn_band_window_for_active_sade_sati() -> None:
    jd = _transit_jd()
    # As of mid-2026 Saturn sits in Pisces (sign 11). A natal Moon in Pisces puts
    # Saturn over the Moon -> the peak (Madhya) phase of Sade Sati is running.
    moon_sign = 11
    assert gochar.saturn_relative_house(jd, moon_sign) == 1
    start, end = gochar.saturn_band_window(jd, moon_sign, {12, 1, 2})
    assert start is not None and end is not None
    assert start < jd < end
    # The arc spans roughly seven and a half years.
    assert 6.5 * 365 < (end - start) < 8.0 * 365
    # Saturn enters the 12th-from-Moon sign at the start and leaves the 2nd at end.
    assert gochar.sign_index(start + 1.0, "shani") == (moon_sign + 11) % 12
    assert gochar.sign_index(end - 1.0, "shani") == (moon_sign + 1) % 12


def test_saturn_band_window_inactive_returns_none() -> None:
    jd = _transit_jd()
    # Natal Moon in Cancer (sign 3): Saturn (Pisces) is the 9th from it -> no
    # Sade Sati now; the next one is announced instead.
    moon_sign = 3
    start, end = gochar.saturn_band_window(jd, moon_sign, {12, 1, 2})
    assert start is None and end is None
    upcoming = gochar.next_saturn_band_entry(jd, moon_sign, {12, 1, 2})
    assert upcoming is not None and upcoming > jd
