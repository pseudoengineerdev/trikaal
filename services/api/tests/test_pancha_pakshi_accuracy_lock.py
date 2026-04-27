from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from trikaal_api.main import app

FIXTURE_PATH = (
    Path(__file__).resolve().parents[2]
    / ".."
    / "libs"
    / "reference-fixtures"
    / "fixtures"
    / "pancha_pakshi"
    / "realtime_lock_cases_v1.json"
).resolve()


def _load_cases() -> list[dict[str, object]]:
    payload = json.loads(FIXTURE_PATH.read_text(encoding="utf-8"))
    return list(payload["cases"])


CASES = _load_cases()


@pytest.mark.parametrize("case", CASES, ids=[case["id"] for case in CASES])
def test_pancha_pakshi_api_realtime_fixture_lock(case: dict[str, object]) -> None:
    client = TestClient(app)
    response = client.post("/v1/pancha-pakshi/compute", json=case["request"])

    assert response.status_code == 200
    payload = response.json()["pancha_pakshi"]
    expected = case["expected"]

    assert payload["birth"] == expected["birth"]
    assert payload["runtime"]["reference_timezone"] == expected["runtime"]["reference_timezone"]
    assert payload["runtime"]["reference_place_label"] == expected["runtime"]["reference_place_label"]
    assert payload["runtime"]["weekday"] == expected["runtime"]["weekday"]
    assert payload["runtime"]["paksha"] == expected["runtime"]["paksha"]
    assert payload["runtime"]["phase"] == expected["runtime"]["phase"]

    assert payload["active"]["major_index"] == expected["active"]["major_index"]
    assert payload["active"]["main_bird"] == expected["active"]["main_bird"]
    assert payload["active"]["main_activity"] == expected["active"]["main_activity"]
    assert (
        _active_sub_signature(payload["active"]["sub_activity"])
        == _active_sub_signature(expected["active"]["sub_activity"])
    )

    timeline = payload["timeline"]
    expected_signature = expected["timeline_signature"]
    assert [major["main_activity"] for major in timeline] == expected_signature["major_activity_sequence"]
    assert [major["main_bird"] for major in timeline] == expected_signature["major_bird_sequence"]
    assert [major["phase"] for major in timeline] == expected_signature["phase_sequence"]
    assert [major["paksha"] for major in timeline] == expected_signature["paksha_sequence"]
    assert _sub_relation_signature(timeline[0]) == expected_signature["first_window_sub_relations"]

    _assert_api_timeline_shape_invariants(timeline)


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


def _assert_api_timeline_shape_invariants(timeline: list[dict[str, object]]) -> None:
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
