from __future__ import annotations

from vedic_engine.domain import BirthEvent, CalculationProfile


def compute_chart_snapshot(
    *,
    birth_event: BirthEvent,
    profile: CalculationProfile,
) -> dict[str, object]:
    """Return a deterministic stub snapshot for the canonical parity pipeline."""
    is_canonical_case = (
        birth_event.local_date == "1999-07-04"
        and birth_event.local_time == "12:22"
        and birth_event.timezone == "Asia/Kolkata"
        and birth_event.place_label == "Mumbai, India"
        and profile.profile_id == "vedic_drik_lahiri_v1"
    )

    if is_canonical_case:
        return {"meta": {"status": "fixture_seeded"}}

    return {"meta": {"status": "engine_not_implemented"}}
