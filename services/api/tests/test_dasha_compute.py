from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_dasha_compute_returns_vimshottari_result() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/dasha/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Mumbai",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["profile"]["profile_id"] == "vedic_lahiri_v1"
    assert payload["resolved_place"]["place_label"] == "Mumbai, Maharashtra, India"
    assert payload["dasha"]["system"] == "Vimshottari"
    assert isinstance(payload["dasha"]["current_maha_dasha"], str)
    assert isinstance(payload["dasha"]["current_antar_dasha"], str)


def test_dasha_compute_returns_not_found_for_unknown_place() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/dasha/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "zzzzzzzzzz",
        },
    )

    assert response.status_code == 404


def test_dasha_compute_accepts_custom_place_payload() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/dasha/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Custom City",
            "custom_place": {
                "place_label": "Custom City, Testland",
                "latitude": 19.076,
                "longitude": 72.8777,
                "timezone": "Asia/Kolkata",
                "elevation_m": 14.0,
            },
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["resolved_place"]["place_label"] == "Custom City, Testland"
    assert payload["resolved_place"]["timezone"] == "Asia/Kolkata"
    assert payload["dasha"]["system"] == "Vimshottari"
