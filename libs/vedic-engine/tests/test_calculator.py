from vedic_engine.calculator import compute_chart_snapshot
from vedic_engine.domain import BirthEvent, CalculationProfile


def test_calculator_returns_seeded_snapshot_for_canonical_case() -> None:
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

    assert snapshot == {"meta": {"status": "fixture_seeded"}}


def test_calculator_returns_not_implemented_for_non_canonical_case() -> None:
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

    assert snapshot == {"meta": {"status": "engine_not_implemented"}}
