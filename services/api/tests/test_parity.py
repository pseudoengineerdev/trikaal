from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_canonical_reference_parity_check() -> None:
    client = TestClient(app)
    response = client.get("/v1/engine/parity/canonical-reference")

    assert response.status_code == 200
    payload = response.json()
    assert payload["fixture_id"] == "reference_mumbai_1999_07_04_1222_v1"
    assert payload["matched"] is False
    assert payload["difference_count"] == 2
    assert payload["differences"][0]["path"] == "astronomy.moon_sidereal_deg"
    assert payload["differences"][0]["expected"] == 320.35
    assert payload["differences"][0]["actual"] == 320.37
    assert payload["differences"][1]["path"] == "astronomy.sun_sidereal_deg"
    assert payload["differences"][1]["expected"] == 78.02
    assert payload["differences"][1]["actual"] == 78.03
