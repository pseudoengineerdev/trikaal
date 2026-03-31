from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from pydantic import BaseModel

WORKSPACE_ROOT = Path(__file__).resolve().parents[4]
REFERENCE_FIXTURES_SRC = WORKSPACE_ROOT / "libs" / "reference-fixtures" / "src"
VEDIC_ENGINE_SRC = WORKSPACE_ROOT / "libs" / "vedic-engine" / "src"

for path in (REFERENCE_FIXTURES_SRC, VEDIC_ENGINE_SRC):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

from reference_fixtures import ReferenceFixture, compare_snapshots
from vedic_engine import BirthEvent, CalculationProfile, compute_chart_snapshot


class ParityResult(BaseModel):
    fixture_id: str
    matched: bool
    difference_count: int
    differences: list[dict[str, Any]]


def run_canonical_reference_parity_check() -> ParityResult:
    fixture_path = (
        WORKSPACE_ROOT
        / "libs"
        / "reference-fixtures"
        / "fixtures"
        / "reference"
        / "1999-07-04_mumbai_1222.json"
    )
    fixture = ReferenceFixture.model_validate(json.loads(fixture_path.read_text(encoding="utf-8")))

    birth_event = BirthEvent(
        local_date=fixture.birth_input.local_date,
        local_time=fixture.birth_input.local_time,
        timezone=fixture.birth_input.timezone,
        latitude=fixture.birth_input.latitude,
        longitude=fixture.birth_input.longitude,
        elevation_m=fixture.birth_input.elevation_m,
        place_label=fixture.birth_input.place_label,
    )
    profile = CalculationProfile(
        zodiac_system=fixture.profile.zodiac_system,
        ayanamsha=fixture.profile.ayanamsha,
        calculation_method=fixture.profile.calculation_method,
    )
    actual_snapshot = compute_chart_snapshot(birth_event=birth_event, profile=profile)
    differences = compare_snapshots(
        expected_snapshot=fixture.expected_snapshot,
        actual_snapshot=actual_snapshot,
        exact_paths=fixture.comparison_rules.exact_paths,
        float_tolerance=fixture.comparison_rules.float_tolerance,
    )

    return ParityResult(
        fixture_id=fixture.fixture_id,
        matched=len(differences) == 0,
        difference_count=len(differences),
        differences=[
            {
                "path": difference.path,
                "expected": difference.expected,
                "actual": difference.actual,
                "reason": difference.reason,
            }
            for difference in differences
        ],
    )
