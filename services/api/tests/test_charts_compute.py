from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_charts_compute_returns_snapshot_for_simple_birth_input() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/charts/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Mumbai",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["profile"]["profile_id"] == "vedic_drik_lahiri_v1"
    assert payload["resolved_place"]["place_label"] == "Mumbai, India"
    assert payload["snapshot"]["meta"]["status"] == "computed"
    assert payload["snapshot"]["vedic"]["sun_rashi"] == "Mitu"


def test_charts_compute_returns_not_found_for_unknown_place() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/charts/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Atlantis",
        },
    )

    assert response.status_code == 404


def test_charts_compute_rejects_invalid_time_format() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/charts/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22:59",
            "place_of_birth": "Mumbai",
        },
    )

    assert response.status_code == 422
