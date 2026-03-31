from dataclasses import FrozenInstanceError

import pytest

from vedic_engine.domain import BirthEvent, CalculationProfile, ChartSnapshot


def test_default_profile_is_vedic_reference_lahiri() -> None:
    profile = CalculationProfile()

    assert profile.profile_id == "vedic_lahiri_v1"
    assert profile.zodiac_system == "sidereal"
    assert profile.ayanamsha == "lahiri_chitrapaksha"
    assert profile.calculation_method == "modern_ephemeris"


def test_birth_event_is_immutable() -> None:
    event = BirthEvent(
        local_date="1999-07-04",
        local_time="12:22",
        timezone="Asia/Kolkata",
        latitude=19.0760,
        longitude=72.8777,
        elevation_m=14.0,
        place_label="Mumbai, India",
    )

    with pytest.raises(FrozenInstanceError):
        event.local_time = "12:23"  # type: ignore[misc]


def test_chart_snapshot_embeds_birth_event_and_profile() -> None:
    event = BirthEvent(
        local_date="1999-07-04",
        local_time="12:22",
        timezone="Asia/Kolkata",
        latitude=19.0760,
        longitude=72.8777,
        elevation_m=14.0,
        place_label="Mumbai, India",
    )
    profile = CalculationProfile()
    snapshot = ChartSnapshot(
        birth_event=event,
        profile=profile,
        metadata={"source": "reference_panchang"},
    )

    assert snapshot.birth_event.place_label == "Mumbai, India"
    assert snapshot.profile.profile_id == "vedic_lahiri_v1"
    assert snapshot.metadata["source"] == "reference_panchang"
