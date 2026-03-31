from __future__ import annotations

from dataclasses import dataclass
from math import isclose
from typing import Any


@dataclass(frozen=True)
class SnapshotDifference:
    path: str
    expected: Any
    actual: Any
    reason: str


def compare_snapshots(
    *,
    expected_snapshot: dict[str, Any],
    actual_snapshot: dict[str, Any],
    exact_paths: list[str] | None = None,
    float_tolerance: float = 1e-6,
) -> list[SnapshotDifference]:
    exact_match_paths = set(exact_paths or [])
    differences: list[SnapshotDifference] = []
    flattened_expected = _flatten_paths(expected_snapshot)
    flattened_actual = _flatten_paths(actual_snapshot)

    for path in sorted(flattened_expected.keys()):
        expected = flattened_expected.get(path)
        if path not in flattened_actual:
            differences.append(
                SnapshotDifference(
                    path=path,
                    expected=expected,
                    actual=None,
                    reason="missing_path",
                )
            )
            continue

        actual = flattened_actual[path]

        if path in exact_match_paths:
            if str(expected) != str(actual):
                differences.append(
                    SnapshotDifference(
                        path=path,
                        expected=expected,
                        actual=actual,
                        reason="exact_mismatch",
                    )
                )
            continue

        if _both_numbers(expected, actual):
            if not isclose(float(expected), float(actual), abs_tol=float_tolerance, rel_tol=0.0):
                differences.append(
                    SnapshotDifference(
                        path=path,
                        expected=expected,
                        actual=actual,
                        reason="numeric_mismatch",
                    )
                )
            continue

        if expected != actual:
            differences.append(
                SnapshotDifference(
                    path=path,
                    expected=expected,
                    actual=actual,
                    reason="value_mismatch",
                )
            )

    return differences


def _flatten_paths(snapshot: dict[str, Any], parent: str = "") -> dict[str, Any]:
    flattened: dict[str, Any] = {}
    for key, value in snapshot.items():
        current = f"{parent}.{key}" if parent else key
        if isinstance(value, dict):
            flattened.update(_flatten_paths(value, current))
        else:
            flattened[current] = value
    return flattened


def _both_numbers(left: Any, right: Any) -> bool:
    return isinstance(left, (int, float)) and isinstance(right, (int, float))
