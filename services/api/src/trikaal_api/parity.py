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

from reference_fixtures import compare_snapshots

from trikaal_api.canonical import load_canonical_fixture


class ParityResult(BaseModel):
    fixture_id: str
    matched: bool
    difference_count: int
    differences: list[dict[str, Any]]


def run_canonical_drik_parity_check() -> ParityResult:
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
