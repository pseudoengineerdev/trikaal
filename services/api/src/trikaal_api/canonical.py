from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from pydantic import BaseModel

WORKSPACE_ROOT = Path(__file__).resolve().parents[4]
REFERENCE_FIXTURES_SRC = WORKSPACE_ROOT / "libs" / "reference-fixtures" / "src"
VEDIC_ENGINE_SRC = WORKSPACE_ROOT / "libs" / "vedic-engine" / "src"
DRIK_FIXTURE_DIR = WORKSPACE_ROOT / "libs" / "reference-fixtures" / "fixtures" / "drik"

for path in (REFERENCE_FIXTURES_SRC, VEDIC_ENGINE_SRC):
    if str(path) not in sys.path:
        sys.path.insert(0, str(path))

from reference_fixtures import ReferenceFixture  # noqa: E402
from vedic_engine import BirthEvent, CalculationProfile, compute_chart_snapshot  # noqa: E402


class CanonicalPreview(BaseModel):
    fixture_id: str
    birth_input: dict[str, Any]
    profile: dict[str, Any]
    computed_snapshot: dict[str, Any]


def load_canonical_fixture() -> ReferenceFixture:
    fixture_path = DRIK_FIXTURE_DIR / "1999-07-04_mumbai_1222.json"
    return ReferenceFixture.model_validate(json.loads(fixture_path.read_text(encoding="utf-8")))


def load_drik_fixtures() -> list[ReferenceFixture]:
    fixtures: list[ReferenceFixture] = []
    for fixture_path in sorted(DRIK_FIXTURE_DIR.glob("*.json")):
        fixtures.append(
            ReferenceFixture.model_validate(
                json.loads(fixture_path.read_text(encoding="utf-8")),
            )
        )
    return fixtures


def compute_snapshot_for_fixture(fixture: ReferenceFixture) -> dict[str, Any]:
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
    return compute_chart_snapshot(birth_event=birth_event, profile=profile)


def build_canonical_preview() -> CanonicalPreview:
    fixture = load_canonical_fixture()
    snapshot = compute_snapshot_for_fixture(fixture)

    return CanonicalPreview(
        fixture_id=fixture.fixture_id,
        birth_input=fixture.birth_input.model_dump(),
        profile=fixture.profile.model_dump(),
        computed_snapshot=snapshot,
    )
