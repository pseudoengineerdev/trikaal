import json
from pathlib import Path

from reference_fixtures.models import ReferenceFixture


def test_all_drik_fixtures_conform_to_schema() -> None:
    fixture_dir = Path(__file__).resolve().parents[1] / "fixtures" / "drik"
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
        if fixture.is_verified_drik_reference:
            verified_count += 1
        else:
            provisional_count += 1

    assert verified_count >= 25
    assert provisional_count == 0


def test_canonical_fixture_is_present_in_suite() -> None:
    fixture_dir = Path(__file__).resolve().parents[1] / "fixtures" / "drik"
    fixture_paths = sorted(fixture_dir.glob("*.json"))
    fixture_ids = {
        ReferenceFixture.parse_obj(json.loads(path.read_text(encoding="utf-8"))).fixture_id
        for path in fixture_paths
    }

    assert "drik_mumbai_1999_07_04_1222_v1" in fixture_ids


def test_pancha_pakshi_lock_fixture_has_required_coverage() -> None:
    fixture_path = (
        Path(__file__).resolve().parents[1]
        / "fixtures"
        / "pancha_pakshi"
        / "realtime_lock_cases_v1.json"
    )
    payload = json.loads(fixture_path.read_text(encoding="utf-8"))

    assert payload["version"] == "v1"
    cases = payload["cases"]
    assert len(cases) >= 6

    phases = {case["expected"]["runtime"]["phase"] for case in cases}
    pakshas = {case["expected"]["runtime"]["paksha"] for case in cases}
    assert phases == {"day", "night"}
    assert pakshas == {"Shukla", "Krishna"}

    case_ids = {case["id"] for case in cases}
    assert "detroit_krishna_night_dst_start" in case_ids
    assert "newyork_krishna_night_dst_fall" in case_ids
