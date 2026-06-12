from __future__ import annotations

import pytest

from vedic_engine.hindu_calendar import compute_hindu_calendar_month


def test_hindu_calendar_purnimanta_matches_reference_shape() -> None:
    result = compute_hindu_calendar_month(
        year=2026,
        month=5,
        timezone="America/Detroit",
        latitude=42.3314,
        longitude=-83.0458,
        elevation_m=183.0,
        month_type="purnimanta",
    )

    assert result["calendar_profile_id"] == "vedic_hindu_calendar_v1"
    assert result["month_type"] == "purnimanta"
    assert result["day_count"] == 31

    day6 = next(day for day in result["days"] if day["day"] == 6)
    assert day6["lunar_month_name"] == "Jyeshtha"
    assert day6["paksha"] == "Krishna"
    assert day6["tithi_day"] == 5
    assert day6["lunar_day_of_month"] == 5
    assert day6["tithi_name_vedic"] == "Krishna Panchami"

    day17 = next(day for day in result["days"] if day["day"] == 17)
    assert day17["lunar_month_name"] == "Jyeshtha (Adhika)"
    assert day17["paksha"] == "Shukla"
    assert day17["tithi_day"] == 1
    assert day17["lunar_day_of_month"] == 1

    day26 = next(day for day in result["days"] if day["day"] == 26)
    assert day26["lunar_month_name"] == "Jyeshtha (Adhika)"
    assert day26["paksha"] == "Shukla"
    assert day26["lunar_day_of_month"] == 11


def test_hindu_calendar_purnimanta_matches_reference_june_boundary() -> None:
    result = compute_hindu_calendar_month(
        year=2026,
        month=6,
        timezone="America/Detroit",
        latitude=42.3314,
        longitude=-83.0458,
        elevation_m=183.0,
        month_type="purnimanta",
    )

    day13 = next(day for day in result["days"] if day["day"] == 13)
    assert day13["paksha"] == "Krishna"
    assert day13["tithi_day"] == 13
    assert day13["lunar_day_of_month"] == 28
    assert "Adhika" in day13["lunar_month_name"]

    day14 = next(day for day in result["days"] if day["day"] == 14)
    assert day14["paksha"] == "Krishna"
    assert day14["tithi_day"] == 15
    assert day14["lunar_day_of_month"] == 30
    assert "Adhika" in day14["lunar_month_name"]

    day15 = next(day for day in result["days"] if day["day"] == 15)
    assert day15["paksha"] == "Shukla"
    assert day15["tithi_day"] == 1
    assert day15["lunar_day_of_month"] == 16
    assert day15["lunar_month_name"] == "Jyeshtha"

    day16 = next(day for day in result["days"] if day["day"] == 16)
    assert day16["paksha"] == "Shukla"
    assert day16["tithi_day"] == 2
    assert day16["lunar_day_of_month"] == 17

    day30 = next(day for day in result["days"] if day["day"] == 30)
    assert day30["paksha"] == "Krishna"
    assert day30["tithi_day"] == 1
    assert day30["lunar_day_of_month"] == 1
    assert day30["lunar_month_name"] == "Ashadha"


def test_hindu_calendar_amanta_shifts_krishna_paksha_month_naming() -> None:
    result = compute_hindu_calendar_month(
        year=2026,
        month=5,
        timezone="America/Detroit",
        latitude=42.3314,
        longitude=-83.0458,
        elevation_m=183.0,
        month_type="amanta",
    )

    day6 = next(day for day in result["days"] if day["day"] == 6)
    assert day6["lunar_month_name"] == "Vaishakha"
    assert day6["paksha"] == "Krishna"
    assert day6["tithi_day"] == 5
    assert day6["lunar_day_of_month"] == 20


def test_hindu_calendar_amanta_marks_adhika_month() -> None:
    result = compute_hindu_calendar_month(
        year=2026,
        month=5,
        timezone="America/Detroit",
        latitude=42.3314,
        longitude=-83.0458,
        elevation_m=183.0,
        month_type="amanta",
    )

    day17 = next(day for day in result["days"] if day["day"] == 17)
    assert day17["lunar_month_name"] == "Jyeshtha (Adhika)"
    assert day17["paksha"] == "Shukla"
    assert day17["lunar_day_of_month"] == 1

    day31 = next(day for day in result["days"] if day["day"] == 31)
    assert day31["lunar_month_name"] == "Jyeshtha (Adhika)"
    assert day31["paksha"] == "Krishna"
    assert day31["lunar_day_of_month"] == 16


def test_hindu_calendar_uses_local_sunrise_for_detroit_june_transitions() -> None:
    result = compute_hindu_calendar_month(
        year=2026,
        month=6,
        timezone="America/Detroit",
        latitude=42.3314,
        longitude=-83.0458,
        elevation_m=183.0,
        month_type="amanta",
    )

    day14 = next(day for day in result["days"] if day["day"] == 14)
    assert day14["sunrise_local_time"] == "06:00"
    assert day14["sunset_local_time"] == "21:04"
    assert day14["tithi_number"] == 30
    assert day14["lunar_day_of_month"] == 30
    assert day14["tithi_name_vedic"] == "Amavasya"

    day21 = next(day for day in result["days"] if day["day"] == 21)
    assert day21["sunrise_local_time"] == "06:00"
    assert day21["sunset_local_time"] == "21:07"
    assert day21["tithi_number"] == 8
    assert day21["lunar_day_of_month"] == 8
    assert day21["tithi_name_vedic"] == "Shukla Ashtami"


def test_hindu_calendar_sun_events_and_nakshatra_match_reference() -> None:
    result = compute_hindu_calendar_month(
        year=2026,
        month=5,
        timezone="America/Detroit",
        latitude=42.3314,
        longitude=-83.0458,
        elevation_m=183.0,
        month_type="purnimanta",
    )

    day5 = next(day for day in result["days"] if day["day"] == 5)
    assert day5["sunrise_local_time"] == "06:27"
    assert day5["sunset_local_time"] == "20:31"
    assert day5["moon_rashi"] == "Dhanu"
    assert day5["nakshatra_name"] == "Mula"

    # Moon sits at 253.3 deg at sunrise: the disc-center sunrise convention is
    # what keeps this on the reference side of the Mula / P Ashadha boundary.
    day6 = next(day for day in result["days"] if day["day"] == 6)
    assert day6["nakshatra_name"] == "P Ashadha"

    day31 = next(day for day in result["days"] if day["day"] == 31)
    assert day31["sunrise_local_time"] == "06:03"
    assert day31["sunset_local_time"] == "20:56"
    assert day31["moon_rashi"] == "Vrischika"
    assert day31["nakshatra_name"] == "Anuradha"
    assert day31["nakshatra_number"] == 17


def test_hindu_calendar_handles_circumpolar_months_without_sun_events() -> None:
    for month in (6, 12):
        result = compute_hindu_calendar_month(
            year=2026,
            month=month,
            timezone="Europe/Oslo",
            latitude=69.6492,
            longitude=18.9553,
            elevation_m=10.0,
            month_type="purnimanta",
        )

        day15 = next(day for day in result["days"] if day["day"] == 15)
        assert day15["sunrise_local_time"] == ""
        assert day15["sunset_local_time"] == ""
        # Panchang falls back to a local-noon anchor and stays computable.
        assert day15["tithi_name_vedic"]
        assert day15["nakshatra_name"]


def test_hindu_calendar_reports_today_in_location_timezone() -> None:
    result = compute_hindu_calendar_month(
        year=2026,
        month=5,
        timezone="America/Detroit",
        latitude=42.3314,
        longitude=-83.0458,
        elevation_m=183.0,
        month_type="purnimanta",
    )

    assert len(str(result["today_local_date"])) == 10


def test_hindu_calendar_rejects_invalid_month_type() -> None:
    with pytest.raises(ValueError, match="Unsupported month_type"):
        compute_hindu_calendar_month(
            year=2026,
            month=5,
            timezone="America/Detroit",
            latitude=42.3314,
            longitude=-83.0458,
            elevation_m=183.0,
            month_type="invalid",
        )
