from __future__ import annotations

import csv
import importlib.util
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from functools import lru_cache
from pathlib import Path
from zoneinfo import ZoneInfo

from vedic_engine.calculator import compute_chart_snapshot
from vedic_engine.domain import BirthEvent, CalculationProfile

BIRD_NAMES = ("Vulture", "Owl", "Crow", "Cock", "Peacock")
ACTIVITY_NAMES = ("Ruling", "Eating", "Walking", "Sleeping", "Dying")
EFFECT_NAMES = ("Very Bad", "Bad", "Average", "Good", "Very Good")
WEEKDAY_NAMES = ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")

# Paksha-aware friend/enemy relationship sequences.
# Rule: for a given birth bird, adjacent birds in the sequence are friends;
# the remaining two are enemies. Same bird is "Same".
# Shukla (bright): Vulture -> Owl -> Crow -> Cock -> Peacock
# Krishna (dark): Vulture -> Crow -> Owl -> Cock -> Peacock
RELATION_SEQUENCE_BY_PAKSHA: dict[int, tuple[int, int, int, int, int]] = {
    0: (0, 1, 2, 3, 4),
    1: (0, 2, 1, 3, 4),
}

# Activity duration units by paksha and phase, normalized on a 24-unit scale.
# Activity index order: Ruling(0), Eating(1), Walking(2), Sleeping(3), Dying(4)
#
# These are Drik-parity weights and intentionally replace legacy CSV duration
# factors which were producing mismatched sub-window timings.
DURATION_UNITS_BY_PAKSHA_PHASE: dict[tuple[int, str], tuple[int, int, int, int, int]] = {
    # Shukla Paksha
    (0, "day"): (8, 5, 6, 3, 2),
    (0, "night"): (4, 5, 5, 4, 6),
    # Krishna Paksha
    (1, "day"): (3, 8, 6, 2, 5),
    (1, "night"): (3, 7, 7, 3, 4),
}

# Each tuple: (Shukla Paksha bird, Krishna Paksha bird), indexed by Nakshatra 1..27.
STAR_BIRD_BY_PAKSHA: tuple[tuple[int, int], ...] = (
    (1, 5),
    (1, 5),
    (1, 5),
    (1, 5),
    (1, 5),
    (2, 4),
    (2, 4),
    (2, 4),
    (2, 4),
    (2, 4),
    (2, 4),
    (3, 3),
    (3, 3),
    (3, 3),
    (3, 3),
    (3, 3),
    (4, 2),
    (4, 2),
    (4, 2),
    (4, 2),
    (4, 2),
    (5, 1),
    (5, 1),
    (5, 1),
    (5, 1),
    (5, 1),
    (5, 1),
)


@dataclass(frozen=True)
class PanchaPakshiRuleRow:
    week_day_index: int
    paksha_index: int
    daynight_index: int
    nak_bird_index: int
    main_bird_index: int
    main_activity_index: int
    sub_bird_index: int
    sub_activity_index: int
    power_factor: float
    effect: int
    rating: int


def compute_pancha_pakshi_live(
    *,
    birth_event: BirthEvent,
    profile: CalculationProfile,
    as_of: datetime | None = None,
    runtime_reference_event: BirthEvent | None = None,
) -> dict[str, object]:
    reference_event = runtime_reference_event or birth_event
    tz = ZoneInfo(reference_event.timezone)
    as_of_local = _normalize_as_of(as_of=as_of, timezone=tz)

    birth_snapshot = compute_chart_snapshot(
        birth_event=birth_event,
        profile=profile,
    )
    birth_nakshatra_number = int(birth_snapshot["panchanga"]["nakshatra"]["number"])
    birth_nakshatra_name = str(birth_snapshot["panchanga"]["nakshatra"]["name_vedic"])
    birth_paksha_name = str(birth_snapshot["panchanga"]["tithi"]["paksha"])
    birth_paksha_index = _paksha_index_from_name(birth_paksha_name)
    birth_bird_index_1 = STAR_BIRD_BY_PAKSHA[birth_nakshatra_number - 1][birth_paksha_index]
    birth_bird_index_0 = birth_bird_index_1 - 1

    anchor = _resolve_anchor_window(
        as_of_local=as_of_local,
        birth_event=reference_event,
        profile=profile,
    )
    phase_name = anchor["phase_name"]
    phase_start = anchor["phase_start"]
    phase_end = anchor["phase_end"]
    current_phase = _build_phase_timeline(
        anchor=anchor,
        birth_bird_index_0=birth_bird_index_0,
        reference_event=reference_event,
        profile=profile,
        major_index_offset=0,
    )
    major_timeline = current_phase["timeline"]
    weekday_index = current_phase["weekday_index"]
    anchor_paksha_index = current_phase["paksha_index"]

    next_phase_anchor = _resolve_anchor_window(
        as_of_local=phase_end,
        birth_event=reference_event,
        profile=profile,
    )
    next_phase = _build_phase_timeline(
        anchor=next_phase_anchor,
        birth_bird_index_0=birth_bird_index_0,
        reference_event=reference_event,
        profile=profile,
        major_index_offset=5,
    )
    combined_timeline = major_timeline + next_phase["timeline"]
    active_window = _find_active_window(
        major_timeline=major_timeline,
        as_of_local=as_of_local,
    )
    next_transition = datetime.fromisoformat(active_window["sub_activity"]["end_local_iso"])
    seconds_remaining = max(0, int((next_transition - as_of_local).total_seconds()))

    return {
        "version": "v1",
        "birth": {
            "nakshatra_number": birth_nakshatra_number,
            "nakshatra_name": birth_nakshatra_name,
            "paksha": birth_paksha_name,
            "pakshi": BIRD_NAMES[birth_bird_index_0],
        },
        "runtime": {
            "as_of_local_iso": as_of_local.isoformat(timespec="seconds"),
            "reference_place_label": reference_event.place_label,
            "reference_timezone": reference_event.timezone,
            "weekday": WEEKDAY_NAMES[weekday_index],
            "paksha": _paksha_name_from_index(anchor_paksha_index),
            "phase": phase_name,
            "phase_window_start_local_iso": phase_start.isoformat(timespec="seconds"),
            "phase_window_end_local_iso": phase_end.isoformat(timespec="seconds"),
            "next_transition_local_iso": next_transition.isoformat(timespec="seconds"),
            "seconds_remaining_in_active_sub_activity": seconds_remaining,
        },
        "active": active_window,
        "timeline": combined_timeline,
    }


def _build_major_timeline(
    *,
    rows: list[PanchaPakshiRuleRow],
    phase_start: datetime,
    phase_end: datetime,
    phase_name: str,
    paksha_name: str,
    paksha_index: int,
    birth_bird_index_0: int,
    major_index_offset: int = 0,
) -> list[dict[str, object]]:
    timeline: list[dict[str, object]] = []
    phase_duration = phase_end - phase_start
    major_duration = phase_duration / 5

    for major_index in range(5):
        major_start = phase_start + (major_duration * major_index)
        major_end = phase_start + (major_duration * (major_index + 1))
        group = rows[major_index * 5 : (major_index + 1) * 5]
        if len(group) != 5:
            raise RuntimeError("Pancha Pakshi major group must have 5 sub rows.")

        sub_timeline: list[dict[str, object]] = []
        cursor = major_start
        major_span = major_end - major_start
        for sub_index, row in enumerate(group):
            if sub_index == 4:
                sub_end = major_end
            else:
                sub_end = cursor + (
                    major_span
                    * _duration_factor_for_sub_activity(
                        paksha_index=paksha_index,
                        phase_name=phase_name,
                        sub_activity_index=row.sub_activity_index,
                    )
                )
            sub_timeline.append(
                {
                    "start_local_iso": cursor.isoformat(timespec="seconds"),
                    "end_local_iso": sub_end.isoformat(timespec="seconds"),
                    "bird": BIRD_NAMES[row.sub_bird_index],
                    "activity": ACTIVITY_NAMES[row.sub_activity_index],
                    "relation": _relation_label_for_sub_bird(
                        paksha_index=paksha_index,
                        birth_bird_index_0=birth_bird_index_0,
                        sub_bird_index=row.sub_bird_index,
                    ),
                    "effect": EFFECT_NAMES[row.effect],
                    "power_factor": round(row.power_factor, 4),
                    "rating": row.rating,
                    "duration_minutes": round((sub_end - cursor).total_seconds() / 60.0, 2),
                }
            )
            cursor = sub_end

        main_row = group[0]
        timeline.append(
            {
                "major_index": major_index_offset + major_index + 1,
                "phase": phase_name,
                "paksha": paksha_name,
                "start_local_iso": major_start.isoformat(timespec="seconds"),
                "end_local_iso": major_end.isoformat(timespec="seconds"),
                "main_bird": BIRD_NAMES[main_row.main_bird_index],
                "main_activity": ACTIVITY_NAMES[main_row.main_activity_index],
                "duration_minutes": round((major_end - major_start).total_seconds() / 60.0, 2),
                "sub_timeline": sub_timeline,
            }
        )
    return timeline


def _build_phase_timeline(
    *,
    anchor: dict[str, object],
    birth_bird_index_0: int,
    reference_event: BirthEvent,
    profile: CalculationProfile,
    major_index_offset: int,
) -> dict[str, object]:
    anchor_date = anchor["anchor_date"]
    phase_index = anchor["phase_index"]
    phase_start = anchor["phase_start"]
    phase_end = anchor["phase_end"]

    anchor_event = _birth_event_for_date_time(
        birth_event=reference_event,
        local_date=anchor_date,
        local_time=phase_start.strftime("%H:%M"),
    )
    anchor_snapshot = compute_chart_snapshot(
        birth_event=anchor_event,
        profile=profile,
    )
    paksha_name = str(anchor_snapshot["panchanga"]["tithi"]["paksha"])
    paksha_index = _paksha_index_from_name(paksha_name)
    weekday_index = (anchor_date.weekday() + 1) % 7

    key = (weekday_index, paksha_index, phase_index, birth_bird_index_0)
    rows = list(_pancha_pakshi_rule_table().get(key, ()))
    if len(rows) != 25:
        raise RuntimeError(f"Pancha Pakshi rule table missing rows for key={key}")

    timeline = _build_major_timeline(
        rows=rows,
        phase_start=phase_start,
        phase_end=phase_end,
        phase_name=anchor["phase_name"],
        paksha_name=paksha_name,
        paksha_index=paksha_index,
        birth_bird_index_0=birth_bird_index_0,
        major_index_offset=major_index_offset,
    )
    return {
        "timeline": timeline,
        "weekday_index": weekday_index,
        "paksha_name": paksha_name,
        "paksha_index": paksha_index,
    }


def _find_active_window(
    *,
    major_timeline: list[dict[str, object]],
    as_of_local: datetime,
) -> dict[str, object]:
    for major in major_timeline:
        major_start = datetime.fromisoformat(str(major["start_local_iso"]))
        major_end = datetime.fromisoformat(str(major["end_local_iso"]))
        if major_start <= as_of_local < major_end:
            for sub in major["sub_timeline"]:
                sub_start = datetime.fromisoformat(str(sub["start_local_iso"]))
                sub_end = datetime.fromisoformat(str(sub["end_local_iso"]))
                if sub_start <= as_of_local < sub_end:
                    return {
                        "major_index": major["major_index"],
                        "main_bird": major["main_bird"],
                        "main_activity": major["main_activity"],
                        "sub_activity": sub,
                    }
            return {
                "major_index": major["major_index"],
                "main_bird": major["main_bird"],
                "main_activity": major["main_activity"],
                "sub_activity": major["sub_timeline"][-1],
            }

    last_major = major_timeline[-1]
    return {
        "major_index": last_major["major_index"],
        "main_bird": last_major["main_bird"],
        "main_activity": last_major["main_activity"],
        "sub_activity": last_major["sub_timeline"][-1],
    }


def _resolve_anchor_window(
    *,
    as_of_local: datetime,
    birth_event: BirthEvent,
    profile: CalculationProfile,
) -> dict[str, object]:
    today_events = _sun_events_for_date(
        local_date=as_of_local.date(),
        birth_event=birth_event,
        profile=profile,
    )
    sunrise_today = today_events["sunrise"]
    sunset_today = today_events["sunset"]

    if sunrise_today <= as_of_local < sunset_today:
        return {
            "anchor_date": as_of_local.date(),
            "phase_name": "day",
            "phase_index": 0,
            "phase_start": sunrise_today,
            "phase_end": sunset_today,
        }

    if as_of_local < sunrise_today:
        anchor_date = as_of_local.date() - timedelta(days=1)
        previous_events = _sun_events_for_date(
            local_date=anchor_date,
            birth_event=birth_event,
            profile=profile,
        )
        return {
            "anchor_date": anchor_date,
            "phase_name": "night",
            "phase_index": 1,
            "phase_start": previous_events["sunset"],
            "phase_end": sunrise_today,
        }

    next_events = _sun_events_for_date(
        local_date=as_of_local.date() + timedelta(days=1),
        birth_event=birth_event,
        profile=profile,
    )
    return {
        "anchor_date": as_of_local.date(),
        "phase_name": "night",
        "phase_index": 1,
        "phase_start": sunset_today,
        "phase_end": next_events["sunrise"],
    }


def _sun_events_for_date(
    *,
    local_date: date,
    birth_event: BirthEvent,
    profile: CalculationProfile,
) -> dict[str, datetime]:
    event = _birth_event_for_date_time(
        birth_event=birth_event,
        local_date=local_date,
        local_time="12:00",
    )
    snapshot = compute_chart_snapshot(
        birth_event=event,
        profile=profile,
    )
    sunrise = datetime.fromisoformat(str(snapshot["panchanga"]["sunrise"]["local_iso"]))
    sunset = datetime.fromisoformat(str(snapshot["panchanga"]["sunset"]["local_iso"]))
    return {"sunrise": sunrise, "sunset": sunset}


def _birth_event_for_date_time(
    *,
    birth_event: BirthEvent,
    local_date: date,
    local_time: str,
) -> BirthEvent:
    return BirthEvent(
        local_date=local_date.strftime("%Y-%m-%d"),
        local_time=local_time,
        timezone=birth_event.timezone,
        latitude=birth_event.latitude,
        longitude=birth_event.longitude,
        elevation_m=birth_event.elevation_m,
        place_label=birth_event.place_label,
    )


def _normalize_as_of(*, as_of: datetime | None, timezone: ZoneInfo) -> datetime:
    if as_of is None:
        return datetime.now(timezone)
    if as_of.tzinfo is None:
        return as_of.replace(tzinfo=timezone)
    return as_of.astimezone(timezone)


def _paksha_index_from_name(paksha_name: str) -> int:
    normalized = paksha_name.strip().lower()
    if normalized == "shukla":
        return 0
    if normalized == "krishna":
        return 1
    raise ValueError(f"Unsupported paksha value for Pancha Pakshi: {paksha_name}")


def _paksha_name_from_index(paksha_index: int) -> str:
    if paksha_index == 0:
        return "Shukla"
    if paksha_index == 1:
        return "Krishna"
    raise ValueError(f"Unsupported paksha index: {paksha_index}")


def _relation_label_for_sub_bird(
    *,
    paksha_index: int,
    birth_bird_index_0: int,
    sub_bird_index: int,
) -> str:
    if sub_bird_index == birth_bird_index_0:
        return "Same"
    sequence = RELATION_SEQUENCE_BY_PAKSHA.get(paksha_index)
    if sequence is None:
        raise ValueError(f"Unsupported paksha index for relation mapping: {paksha_index}")
    birth_position = sequence.index(birth_bird_index_0)
    left_neighbor = sequence[(birth_position - 1) % 5]
    right_neighbor = sequence[(birth_position + 1) % 5]
    if sub_bird_index in {left_neighbor, right_neighbor}:
        return "Friend"
    return "Enemy"


def _duration_factor_for_sub_activity(
    *,
    paksha_index: int,
    phase_name: str,
    sub_activity_index: int,
) -> float:
    normalized_phase = phase_name.strip().lower()
    units = DURATION_UNITS_BY_PAKSHA_PHASE.get((paksha_index, normalized_phase))
    if units is None:
        raise ValueError(
            f"Unsupported duration rule context: paksha_index={paksha_index}, phase={phase_name}"
        )
    if sub_activity_index < 0 or sub_activity_index >= len(units):
        raise ValueError(f"Unsupported sub activity index: {sub_activity_index}")
    return units[sub_activity_index] / 24.0


@lru_cache(maxsize=1)
def _pancha_pakshi_rule_table() -> dict[tuple[int, int, int, int], tuple[PanchaPakshiRuleRow, ...]]:
    grouped: dict[tuple[int, int, int, int], list[PanchaPakshiRuleRow]] = {}
    with _pancha_pakshi_csv_path().open(encoding="utf-8-sig", newline="") as csv_file:
        reader = csv.DictReader(csv_file)
        for record in reader:
            row = PanchaPakshiRuleRow(
                week_day_index=int(record["week_day_index"]),
                paksha_index=int(record["paksha_index"]),
                daynight_index=int(record["daynight_index"]),
                nak_bird_index=int(record["nak_bird_index"]),
                main_bird_index=int(record["nak_bird_index"]),
                main_activity_index=int(record["nak_activity_index"]),
                sub_bird_index=int(record["sub_bird_index"]),
                sub_activity_index=int(record["sub_activity_index"]),
                power_factor=float(record["power_factor"]),
                effect=int(record["effect"]),
                rating=int(record["rating"]),
            )
            key = (
                row.week_day_index,
                row.paksha_index,
                row.daynight_index,
                row.nak_bird_index,
            )
            grouped.setdefault(key, []).append(row)
    return {key: tuple(rows) for key, rows in grouped.items()}


def _pancha_pakshi_csv_path() -> Path:
    jhora_spec = importlib.util.find_spec("jhora")
    if jhora_spec is None or not jhora_spec.submodule_search_locations:
        raise RuntimeError(
            "Pancha Pakshi rule table package not installed. "
            "Install pyjhora to enable Pancha Pakshi computation."
        )
    base_path = Path(next(iter(jhora_spec.submodule_search_locations)))
    csv_path = base_path / "data" / "pancha_pakshi_db.csv"
    if not csv_path.exists():
        raise RuntimeError(f"Pancha Pakshi rule table not found at: {csv_path}")
    return csv_path
