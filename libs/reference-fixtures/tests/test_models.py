import json
from pathlib import Path

from reference_fixtures.models import ReferenceFixture


def test_all_reference_fixtures_conform_to_schema() -> None:
    fixture_dir = Path(__file__).resolve().parents[1] / "fixtures" / "reference"
    fixture_paths = sorted(fixture_dir.glob("*.json"))

    assert len(fixture_paths) >= 25

    fixture_ids: set[str] = set()
    verified_count = 0
    provisional_count = 0
    for fixture_path in fixture_paths:
        fixture_payload = json.loads(fixture_path.read_text(encoding="utf-8"))
        fixture = ReferenceFixture.parse_obj(fixture_payload)
        assert fixture.fixture_id not in fixture_ids
        fixture_ids.add(fixture.fixture_id)
        assert fixture.profile.ayanamsha == "lahiri_chitrapaksha"
        if fixture.is_verified_reference_reference:
            verified_count += 1
        else:
            provisional_count += 1

    assert verified_count >= 25
    assert provisional_count == 0


def test_canonical_fixture_is_present_in_suite() -> None:
    fixture_dir = Path(__file__).resolve().parents[1] / "fixtures" / "reference"
    fixture_paths = sorted(fixture_dir.glob("*.json"))
    fixture_ids = {
        ReferenceFixture.parse_obj(json.loads(path.read_text(encoding="utf-8"))).fixture_id
        for path in fixture_paths
    }

    assert "reference_mumbai_1999_07_04_1222_v1" in fixture_ids
