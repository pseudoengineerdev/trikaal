from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_chart_endpoint_returns_computed_snapshot() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/engine/chart",
        json={
            "local_date": "1999-07-04",
            "local_time": "12:22",
            "timezone": "Asia/Kolkata",
            "latitude": 19.0760,
            "longitude": 72.8777,
            "elevation_m": 14.0,
            "place_label": "Mumbai, India",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["profile"]["profile_id"] == "vedic_drik_lahiri_v1"
    assert payload["snapshot"]["meta"]["status"] == "computed"
    assert payload["snapshot"]["vedic"]["sun_rashi"] == "Mitu"
    assert payload["snapshot"]["vedic"]["moon_rashi"] == "Kumb"
    assert payload["snapshot"]["bhava"]["lagna_house"] == 1


def test_chart_endpoint_rejects_invalid_latitude() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/engine/chart",
        json={
            "local_date": "1999-07-04",
            "local_time": "12:22",
            "timezone": "Asia/Kolkata",
            "latitude": 190.0,
            "longitude": 72.8777,
            "elevation_m": 14.0,
            "place_label": "Mumbai, India",
        },
    )

    assert response.status_code == 422
