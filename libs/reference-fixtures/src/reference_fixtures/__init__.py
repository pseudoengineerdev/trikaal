"""Reference fixture schema and comparator utilities."""

from reference_fixtures.comparator import SnapshotDifference, compare_snapshots
from reference_fixtures.models import FixtureReferenceStatus, ReferenceFixture

__all__ = [
    "FixtureReferenceStatus",
    "ReferenceFixture",
    "SnapshotDifference",
    "compare_snapshots",
]
