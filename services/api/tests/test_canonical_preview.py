from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_canonical_preview_returns_computed_sun_moon_values() -> None:
    client = TestClient(app)
    response = client.get("/v1/engine/canonical-preview")

    assert response.status_code == 200
    payload = response.json()
    assert payload["fixture_id"] == "reference_mumbai_1999_07_04_1222_v1"
    assert payload["birth_input"]["place_label"] == "Mumbai, India"
    assert payload["profile"]["ayanamsha"] == "lahiri_chitrapaksha"
    assert payload["computed_snapshot"]["meta"]["status"] == "computed"
    assert isinstance(payload["computed_snapshot"]["astronomy"]["sun_sidereal_deg"], float)
    assert isinstance(payload["computed_snapshot"]["astronomy"]["moon_sidereal_deg"], float)
