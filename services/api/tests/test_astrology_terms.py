from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_astrology_terms_endpoint_returns_contract() -> None:
    client = TestClient(app)
    response = client.get("/v1/metadata/astrology-terms")

    assert response.status_code == 200
    payload = response.json()
    assert payload["version"] == "v1"
    assert payload["rashi"]["Kany"]["vedic"] == "Kanya"
    assert payload["rashi"]["Kany"]["english"] == "Virgo"
    assert payload["nakshatra"]["Hasta"]["english"] == "Hasta (The Hand)"
    assert payload["graha"]["sun"]["vedic"] == "Surya"
    assert payload["graha"]["sun"]["english"] == "Sun"
