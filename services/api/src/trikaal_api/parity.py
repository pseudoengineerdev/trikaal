from __future__ import annotations

import sys
from datetime import datetime
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

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
    reference_status: str
    verified_reference: bool
    matched: bool
    difference_count: int
    compared_field_count: int
    matched_field_count: int
    accuracy_percent: float
    differences: list[dict[str, Any]]


class ParitySuiteResult(BaseModel):
    available_fixture_count: int
    fixture_count: int
    include_unverified: bool
    verified_fixture_count: int
    unverified_fixture_count: int
    matched_fixture_count: int
    mismatched_fixture_count: int
    compared_field_count: int
    matched_field_count: int
    accuracy_percent: float
    all_matched: bool
    coverage: dict[str, Any]
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


def run_reference_parity_suite_check(*, include_unverified: bool = False) -> ParitySuiteResult:
    available_fixtures = load_reference_fixtures()
    fixtures = [
        fixture
        for fixture in available_fixtures
        if include_unverified or fixture.is_verified_reference_reference
    ]
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
                reference_status=fixture.reference_status.value,
                verified_reference=fixture.is_verified_reference_reference,
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

    verified_fixture_count = len(
        [fixture for fixture in available_fixtures if fixture.is_verified_reference_reference]
    )
    unverified_fixture_count = len(available_fixtures) - verified_fixture_count

    return ParitySuiteResult(
        available_fixture_count=len(available_fixtures),
        fixture_count=len(fixture_results),
        include_unverified=include_unverified,
        verified_fixture_count=verified_fixture_count,
        unverified_fixture_count=unverified_fixture_count,
        matched_fixture_count=matched_fixture_count,
        mismatched_fixture_count=mismatched_fixture_count,
        compared_field_count=total_compared,
        matched_field_count=total_matched,
        accuracy_percent=overall_accuracy,
        all_matched=mismatched_fixture_count == 0,
        coverage=_build_coverage_summary(fixtures),
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


def _build_coverage_summary(fixtures: list[Any]) -> dict[str, Any]:
    if not fixtures:
        return {
            "timezone_count": 0,
            "country_count": 0,
            "min_birth_year": None,
            "max_birth_year": None,
            "northern_fixture_count": 0,
            "southern_fixture_count": 0,
            "equatorial_fixture_count": 0,
            "dst_observing_timezone_count": 0,
            "timezones": [],
            "countries": [],
        }

    timezones = sorted({fixture.birth_input.timezone for fixture in fixtures})
    countries = sorted({_extract_country(fixture.birth_input.place_label) for fixture in fixtures})
    years = sorted(int(fixture.birth_input.local_date.split("-")[0]) for fixture in fixtures)

    northern_count = len([fixture for fixture in fixtures if fixture.birth_input.latitude > 0])
    southern_count = len([fixture for fixture in fixtures if fixture.birth_input.latitude < 0])
    equatorial_count = len(
        [fixture for fixture in fixtures if fixture.birth_input.latitude == 0]
    )
    dst_count = len([timezone for timezone in timezones if _timezone_observes_dst(timezone)])

    return {
        "timezone_count": len(timezones),
        "country_count": len(countries),
        "min_birth_year": years[0],
        "max_birth_year": years[-1],
        "northern_fixture_count": northern_count,
        "southern_fixture_count": southern_count,
        "equatorial_fixture_count": equatorial_count,
        "dst_observing_timezone_count": dst_count,
        "timezones": timezones,
        "countries": countries,
    }


def _extract_country(place_label: str) -> str:
    segments = [segment.strip() for segment in place_label.split(",") if segment.strip()]
    if not segments:
        return "Unknown"
    return segments[-1]


def _timezone_observes_dst(timezone_name: str) -> bool:
    zone = ZoneInfo(timezone_name)
    january_offset = datetime(2024, 1, 1, 12, 0, tzinfo=zone).utcoffset()
    july_offset = datetime(2024, 7, 1, 12, 0, tzinfo=zone).utcoffset()
    return january_offset != july_offset
