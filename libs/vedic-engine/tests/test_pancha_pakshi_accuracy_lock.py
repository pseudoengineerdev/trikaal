from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

import pytest

from vedic_engine import BirthEvent, CalculationProfile, compute_pancha_pakshi_live
from vedic_engine.pancha_pakshi import ACTIVITY_NAMES, DURATION_UNITS_BY_PAKSHA_PHASE

FIXTURE_PATH = (
    Path(__file__).resolve().parents[2]
    / "reference-fixtures"
    / "fixtures"
    / "pancha_pakshi"
    / "realtime_lock_cases_v1.json"
)


def _load_cases() -> list[dict[str, object]]:
    payload = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    return list(payload["cases"])


CASES = _load_cases()


@pytest.mark.parametrize("case", CASES, ids=[case["id"] for case in CASES])
def test_pancha_pakshi_engine_realtime_fixture_lock(case: dict[str, object]) -> None:
    request = case["request"]
    expected = case["expected"]

    custom_place = request["custom_place"]
    birth_event = BirthEvent(
        local_date=request["date_of_birth"],
        local_time=request["time_of_birth"],
        timezone=custom_place["timezone"],
        latitude=custom_place["latitude"],
        longitude=custom_place["longitude"],
        elevation_m=custom_place["elevation_m"],
        place_label=custom_place["place_label"],
    )
    runtime_custom_place = request.get("runtime_custom_place")
    runtime_reference_event = None
    if runtime_custom_place is not None:
        runtime_reference_event = BirthEvent(
            local_date=request["date_of_birth"],
            local_time=request["time_of_birth"],
            timezone=runtime_custom_place["timezone"],
            latitude=runtime_custom_place["latitude"],
            longitude=runtime_custom_place["longitude"],
            elevation_m=runtime_custom_place["elevation_m"],
            place_label=runtime_custom_place["place_label"],
        )

    result = compute_pancha_pakshi_live(
        birth_event=birth_event,
        profile=CalculationProfile(),
        as_of=datetime.fromisoformat(request["as_of_local_iso"]),
        runtime_reference_event=runtime_reference_event,
    )

    assert result["birth"] == expected["birth"]
    assert result["runtime"]["reference_timezone"] == expected["runtime"]["reference_timezone"]
    assert result["runtime"]["reference_place_label"] == expected["runtime"]["reference_place_label"]
    assert result["runtime"]["weekday"] == expected["runtime"]["weekday"]
    assert result["runtime"]["paksha"] == expected["runtime"]["paksha"]
    assert result["runtime"]["phase"] == expected["runtime"]["phase"]

    assert result["active"]["major_index"] == expected["active"]["major_index"]
    assert result["active"]["main_bird"] == expected["active"]["main_bird"]
    assert result["active"]["main_activity"] == expected["active"]["main_activity"]
    assert (
        _active_sub_signature(result["active"]["sub_activity"])
        == _active_sub_signature(expected["active"]["sub_activity"])
    )

    timeline = result["timeline"]
    expected_signature = expected["timeline_signature"]
    assert [major["main_activity"] for major in timeline] == expected_signature["major_activity_sequence"]
    assert [major["main_bird"] for major in timeline] == expected_signature["major_bird_sequence"]
    assert [major["phase"] for major in timeline] == expected_signature["phase_sequence"]
    assert [major["paksha"] for major in timeline] == expected_signature["paksha_sequence"]
    assert _sub_relation_signature(timeline[0]) == expected_signature["first_window_sub_relations"]

    _assert_timeline_integrity(timeline)
    _assert_duration_ratio_invariants(timeline)


def _active_sub_signature(sub: dict[str, object]) -> tuple[str, str, str, str]:
    return (
        str(sub["bird"]),
        str(sub["activity"]),
        str(sub["relation"]),
        str(sub["effect"]),
    )


def _sub_relation_signature(major: dict[str, object]) -> list[dict[str, str]]:
    return [
        {
            "bird": str(sub["bird"]),
            "relation": str(sub["relation"]),
            "activity": str(sub["activity"]),
        }
        for sub in major["sub_timeline"]
    ]


def _assert_timeline_integrity(timeline: list[dict[str, object]]) -> None:
    assert len(timeline) == 10
    assert [int(item["major_index"]) for item in timeline] == list(range(1, 11))

    previous_major_end: datetime | None = None
    for major in timeline:
        major_start = datetime.fromisoformat(str(major["start_local_iso"]))
        major_end = datetime.fromisoformat(str(major["end_local_iso"]))
        assert major_start < major_end
        if previous_major_end is not None:
            assert major_start == previous_major_end
        previous_major_end = major_end

        sub_timeline = list(major["sub_timeline"])
        assert len(sub_timeline) == 5

        cursor = major_start
        total_sub_minutes = 0.0
        for sub in sub_timeline:
            sub_start = datetime.fromisoformat(str(sub["start_local_iso"]))
            sub_end = datetime.fromisoformat(str(sub["end_local_iso"]))
            assert sub_start == cursor
            assert sub_start < sub_end
            cursor = sub_end
            total_sub_minutes += float(sub["duration_minutes"])

        assert sub_timeline[0]["start_local_iso"] == major["start_local_iso"]
        assert sub_timeline[-1]["end_local_iso"] == major["end_local_iso"]
        assert abs(total_sub_minutes - float(major["duration_minutes"])) <= 0.15


def _assert_duration_ratio_invariants(timeline: list[dict[str, object]]) -> None:
    for major in timeline:
        paksha_index = 0 if str(major["paksha"]) == "Shukla" else 1
        phase_name = str(major["phase"])
        major_minutes = float(major["duration_minutes"])
        expected_units = DURATION_UNITS_BY_PAKSHA_PHASE[(paksha_index, phase_name)]
        expected_ratios = {
            ACTIVITY_NAMES[index]: expected_units[index] / 24.0
            for index in range(len(ACTIVITY_NAMES))
        }
        for sub in major["sub_timeline"]:
            activity_name = str(sub["activity"])
            observed_ratio = float(sub["duration_minutes"]) / major_minutes
            assert abs(observed_ratio - expected_ratios[activity_name]) <= 0.03
