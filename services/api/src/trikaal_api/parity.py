from __future__ import annotations

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

from reference_fixtures import compare_snapshots  # noqa: E402

from trikaal_api.canonical import (  # noqa: E402
    compute_snapshot_for_fixture,
    load_canonical_fixture,
    load_reference_fixtures,
)


class ParityResult(BaseModel):
    fixture_id: str
    matched: bool
    difference_count: int
    differences: list[dict[str, Any]]


class FixtureParityResult(BaseModel):
    fixture_id: str
    source: str
    matched: bool
    difference_count: int
    compared_field_count: int
    matched_field_count: int
    accuracy_percent: float
    differences: list[dict[str, Any]]


class ParitySuiteResult(BaseModel):
    fixture_count: int
    matched_fixture_count: int
    mismatched_fixture_count: int
    compared_field_count: int
    matched_field_count: int
    accuracy_percent: float
    all_matched: bool
    fixtures: list[FixtureParityResult]


def run_canonical_reference_parity_check() -> ParityResult:
    from trikaal_api.canonical import build_canonical_preview

    fixture = load_canonical_fixture()
    actual_snapshot = build_canonical_preview().computed_snapshot
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


def run_reference_parity_suite_check() -> ParitySuiteResult:
    fixtures = load_reference_fixtures()
    fixture_results: list[FixtureParityResult] = []
    total_compared = 0
    total_matched = 0

    for fixture in fixtures:
        actual_snapshot = compute_snapshot_for_fixture(fixture)
        differences = compare_snapshots(
            expected_snapshot=fixture.expected_snapshot,
            actual_snapshot=actual_snapshot,
            exact_paths=fixture.comparison_rules.exact_paths,
            float_tolerance=fixture.comparison_rules.float_tolerance,
        )
        compared_field_count = _count_expected_fields(fixture.expected_snapshot)
        difference_count = len(differences)
        matched_field_count = max(0, compared_field_count - difference_count)
        accuracy_percent = (
            round((matched_field_count / compared_field_count) * 100, 4)
            if compared_field_count > 0
            else 100.0
        )

        total_compared += compared_field_count
        total_matched += matched_field_count

        fixture_results.append(
            FixtureParityResult(
                fixture_id=fixture.fixture_id,
                source=fixture.source,
                matched=difference_count == 0,
                difference_count=difference_count,
                compared_field_count=compared_field_count,
                matched_field_count=matched_field_count,
                accuracy_percent=accuracy_percent,
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
        )

    matched_fixture_count = len([result for result in fixture_results if result.matched])
    mismatched_fixture_count = len(fixture_results) - matched_fixture_count
    overall_accuracy = (
        round((total_matched / total_compared) * 100, 4) if total_compared > 0 else 100.0
    )

    return ParitySuiteResult(
        fixture_count=len(fixture_results),
        matched_fixture_count=matched_fixture_count,
        mismatched_fixture_count=mismatched_fixture_count,
        compared_field_count=total_compared,
        matched_field_count=total_matched,
        accuracy_percent=overall_accuracy,
        all_matched=mismatched_fixture_count == 0,
        fixtures=fixture_results,
    )


def _count_expected_fields(snapshot: dict[str, Any]) -> int:
    return len(_flatten_paths(snapshot))


def _flatten_paths(snapshot: dict[str, Any], parent: str = "") -> dict[str, Any]:
    flattened: dict[str, Any] = {}
    for key, value in snapshot.items():
        current = f"{parent}.{key}" if parent else key
        if isinstance(value, dict):
            flattened.update(_flatten_paths(value, current))
        else:
            flattened[current] = value
    return flattened
