from datetime import datetime
from zoneinfo import ZoneInfo

from vedic_engine.dasha import compute_vimshottari_dasha
from vedic_engine.domain import BirthEvent, CalculationProfile


def test_compute_vimshottari_dasha_returns_expected_shape() -> None:
    result = compute_vimshottari_dasha(
        birth_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, India",
        ),
        profile=CalculationProfile(),
        as_of=datetime(2026, 3, 31, 12, 0, tzinfo=ZoneInfo("Asia/Kolkata")),
    )

    assert result["system"] == "Vimshottari"
    assert isinstance(result["as_of_iso"], str)
    assert isinstance(result["birth_moon_nakshatra"], str)
    assert isinstance(result["current_maha_dasha"], str)
    assert isinstance(result["current_antar_dasha"], str)
    assert isinstance(result["active_from"], str)
    assert isinstance(result["active_until"], str)


def test_compute_vimshottari_dasha_is_deterministic_for_fixed_as_of() -> None:
    kwargs = {
        "birth_event": BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, India",
        ),
        "profile": CalculationProfile(),
        "as_of": datetime(2026, 3, 31, 12, 0, tzinfo=ZoneInfo("Asia/Kolkata")),
    }
    first = compute_vimshottari_dasha(**kwargs)
    second = compute_vimshottari_dasha(**kwargs)

    assert first == second
