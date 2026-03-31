from vedic_engine.calculator import compute_chart_snapshot
from vedic_engine.domain import BirthEvent, CalculationProfile


def test_calculator_returns_computed_snapshot_for_canonical_case() -> None:
    snapshot = compute_chart_snapshot(
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
    )

    assert snapshot["meta"]["status"] == "computed"
    assert snapshot["meta"]["timezone"] == "Asia/Kolkata"
    assert snapshot["meta"]["utc_iso"] == "1999-07-04T06:52:00Z"
    assert isinstance(snapshot["astronomy"]["julian_day_utc"], float)
    assert isinstance(snapshot["astronomy"]["sun_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["moon_sidereal_deg"], float)
    assert isinstance(snapshot["astronomy"]["sun_sidereal_deg_raw"], float)
    assert isinstance(snapshot["astronomy"]["moon_sidereal_deg_raw"], float)
    assert snapshot["astronomy"]["drik_display_offset_deg"] == 0.013


def test_calculator_computes_for_non_canonical_case() -> None:
    snapshot = compute_chart_snapshot(
        birth_event=BirthEvent(
            local_date="2000-01-01",
            local_time="00:00",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, India",
        ),
        profile=CalculationProfile(),
    )

    assert snapshot["meta"]["status"] == "computed"
    assert snapshot["meta"]["utc_iso"] == "1999-12-31T18:30:00Z"
