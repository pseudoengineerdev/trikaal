from datetime import datetime
from zoneinfo import ZoneInfo

from vedic_engine import (
    BirthEvent,
    CalculationProfile,
    compute_pancha_pakshi_live,
)
from vedic_engine.pancha_pakshi import _relation_label_for_sub_bird


def test_pancha_pakshi_returns_realtime_window_for_canonical_input() -> None:
    as_of = datetime(2026, 4, 8, 18, 0, tzinfo=ZoneInfo("Asia/Kolkata"))
    result = compute_pancha_pakshi_live(
        birth_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, Maharashtra, India",
        ),
        profile=CalculationProfile(),
        as_of=as_of,
    )

    assert result["version"] == "v1"
    assert result["birth"]["nakshatra_number"] == 25
    assert result["birth"]["paksha"] == "Krishna"
    assert result["birth"]["pakshi"] == "Vulture"
    assert result["runtime"]["reference_timezone"] == "Asia/Kolkata"
    assert result["runtime"]["phase"] in {"day", "night"}
    assert len(result["timeline"]) == 10
    assert all(len(window["sub_timeline"]) == 5 for window in result["timeline"])

    active = result["active"]["sub_activity"]
    assert isinstance(active["bird"], str)
    assert isinstance(active["activity"], str)
    assert active["relation"] in {"Enemy", "Same", "Friend"}
    assert active["effect"] in {"Very Bad", "Bad", "Average", "Good", "Very Good"}
    assert result["runtime"]["seconds_remaining_in_active_sub_activity"] >= 0


def test_pancha_pakshi_uses_previous_day_anchor_for_pre_sunrise_times() -> None:
    as_of = datetime(2026, 4, 8, 2, 10, tzinfo=ZoneInfo("Asia/Kolkata"))
    result = compute_pancha_pakshi_live(
        birth_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, Maharashtra, India",
        ),
        profile=CalculationProfile(),
        as_of=as_of,
    )

    assert result["runtime"]["phase"] == "night"
    assert result["runtime"]["weekday"] in {
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
    }


def test_pancha_pakshi_accepts_runtime_reference_location() -> None:
    as_of = datetime(2026, 4, 8, 9, 0, tzinfo=ZoneInfo("America/Detroit"))
    result = compute_pancha_pakshi_live(
        birth_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, Maharashtra, India",
        ),
        runtime_reference_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="America/Detroit",
            latitude=42.3314,
            longitude=-83.0458,
            elevation_m=190.0,
            place_label="Detroit, Michigan, United States",
        ),
        profile=CalculationProfile(),
        as_of=as_of,
    )

    assert result["birth"]["pakshi"] == "Vulture"
    assert result["runtime"]["reference_timezone"] == "America/Detroit"
    assert result["runtime"]["reference_place_label"] == "Detroit, Michigan, United States"


def test_pancha_pakshi_relation_rule_is_paksha_driven() -> None:
    # Vulture (index 0) relation rule by paksha:
    # Shukla: friends Owl, Peacock; enemies Crow, Cock
    assert _relation_label_for_sub_bird(
        paksha_index=0,
        birth_bird_index_0=0,
        sub_bird_index=1,
    ) == "Friend"
    assert _relation_label_for_sub_bird(
        paksha_index=0,
        birth_bird_index_0=0,
        sub_bird_index=4,
    ) == "Friend"
    assert _relation_label_for_sub_bird(
        paksha_index=0,
        birth_bird_index_0=0,
        sub_bird_index=2,
    ) == "Enemy"
    assert _relation_label_for_sub_bird(
        paksha_index=0,
        birth_bird_index_0=0,
        sub_bird_index=3,
    ) == "Enemy"

    # Krishna: friends Crow, Peacock; enemies Owl, Cock
    assert _relation_label_for_sub_bird(
        paksha_index=1,
        birth_bird_index_0=0,
        sub_bird_index=2,
    ) == "Friend"
    assert _relation_label_for_sub_bird(
        paksha_index=1,
        birth_bird_index_0=0,
        sub_bird_index=4,
    ) == "Friend"
    assert _relation_label_for_sub_bird(
        paksha_index=1,
        birth_bird_index_0=0,
        sub_bird_index=1,
    ) == "Enemy"
    assert _relation_label_for_sub_bird(
        paksha_index=1,
        birth_bird_index_0=0,
        sub_bird_index=3,
    ) == "Enemy"
    assert _relation_label_for_sub_bird(
        paksha_index=1,
        birth_bird_index_0=0,
        sub_bird_index=0,
    ) == "Same"


def test_pancha_pakshi_runtime_output_respects_paksha_relation_rule() -> None:
    as_of = datetime(2026, 4, 9, 13, 30, tzinfo=ZoneInfo("America/Detroit"))
    result = compute_pancha_pakshi_live(
        birth_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, Maharashtra, India",
        ),
        runtime_reference_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="America/Detroit",
            latitude=42.3314,
            longitude=-83.0458,
            elevation_m=190.0,
            place_label="Detroit, Michigan, United States",
        ),
        profile=CalculationProfile(),
        as_of=as_of,
    )

    # Evaluate current phase (first 5 windows) only.
    relation_map: dict[str, set[str]] = {}
    for major in result["timeline"][:5]:
        for sub in major["sub_timeline"]:
            relation_map.setdefault(str(sub["bird"]), set()).add(str(sub["relation"]))

    # For Krishna paksha Vulture, Crow should stay Friend and Owl should stay Enemy
    # across the full day-phase timeline.
    assert relation_map["Crow"] == {"Friend"}
    assert relation_map["Owl"] == {"Enemy"}


def test_pancha_pakshi_krishna_night_duration_weights_match_reference_parity() -> None:
    as_of = datetime(2026, 4, 9, 20, 40, tzinfo=ZoneInfo("America/Detroit"))
    result = compute_pancha_pakshi_live(
        birth_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="Asia/Kolkata",
            latitude=19.0760,
            longitude=72.8777,
            elevation_m=14.0,
            place_label="Mumbai, Maharashtra, India",
        ),
        runtime_reference_event=BirthEvent(
            local_date="1999-07-04",
            local_time="12:22",
            timezone="America/Detroit",
            latitude=42.3314,
            longitude=-83.0458,
            elevation_m=190.0,
            place_label="Detroit, Michigan, United States",
        ),
        profile=CalculationProfile(),
        as_of=as_of,
    )

    assert result["runtime"]["paksha"] == "Krishna"
    assert result["runtime"]["phase"] == "night"
    major = result["timeline"][0]
    assert major["phase"] == "night"
    assert major["paksha"] == "Krishna"

    expected_units = {
        "Ruling": 3,
        "Eating": 7,
        "Walking": 7,
        "Sleeping": 3,
        "Dying": 4,
    }
    for sub in major["sub_timeline"]:
        expected_ratio = expected_units[sub["activity"]] / 24.0
        actual_ratio = sub["duration_minutes"] / major["duration_minutes"]
        assert abs(actual_ratio - expected_ratio) <= 0.02
