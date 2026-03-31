import json
from pathlib import Path

from reference_fixtures.models import ReferenceFixture


def test_canonical_fixture_conforms_to_schema() -> None:
    fixture_path = (
        Path(__file__).resolve().parents[1]
        / "fixtures"
        / "reference"
        / "1999-07-04_mumbai_1222.json"
    )
    fixture_payload = json.loads(fixture_path.read_text(encoding="utf-8"))
    fixture = ReferenceFixture.model_validate(fixture_payload)

    assert fixture.fixture_id == "reference_mumbai_1999_07_04_1222_v1"
    assert fixture.birth_input.place_label == "Mumbai, India"
    assert fixture.profile.ayanamsha == "lahiri_chitrapaksha"
