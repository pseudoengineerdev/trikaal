from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_kaal_sarpa_compute_returns_rule_contract() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/kaal-sarpa/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Mumbai",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["profile"]["profile_id"] == "vedic_lahiri_v1"
    assert payload["normalized_input"]["local_date"] == "1999-07-04"
    assert payload["resolved_place"]["timezone"] == "Asia/Kolkata"
    assert "snapshot" in payload
    assert payload["kaal_sarpa"]["rule_profile_id"] == "kaal_sarpa_dosha_v1"
    assert (
        payload["kaal_sarpa"]["method"]
        == "all_seven_classical_planets_within_rahu_ketu_axis_no_partial"
    )
    assert "is_partial_candidate" not in payload["kaal_sarpa"]
    assert "reference_partial_included" not in payload["kaal_sarpa"]
    assert "planet_evidence" in payload["kaal_sarpa"]
    assert set(payload["kaal_sarpa"]["classical_planets"]) == {
        "sun",
        "moon",
        "mangal",
        "budha",
        "guru",
        "shukra",
        "shani",
    }


def test_kaal_sarpa_compute_accepts_custom_place_payload() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/kaal-sarpa/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Custom Mumbai",
            "custom_place": {
                "place_label": "Mumbai, Maharashtra, India",
                "latitude": 19.0728,
                "longitude": 72.8825,
                "timezone": "Asia/Kolkata",
                "elevation_m": 14.0,
            },
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["resolved_place"]["place_label"] == "Mumbai, Maharashtra, India"
    assert "kaal_sarpa" in payload
