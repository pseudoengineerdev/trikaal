from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_compatibility_compute_returns_kuta_manglik_and_summary() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/compatibility/compute",
        json={
            "primary": {
                "date_of_birth": "1999-07-04",
                "time_of_birth": "12:22",
                "place_of_birth": "Mumbai",
            },
            "partner": {
                "date_of_birth": "2001-09-09",
                "time_of_birth": "01:30",
                "place_of_birth": "London",
            },
            "primary_role": "boy",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["profile"]["profile_id"] == "vedic_drik_lahiri_v1"
    assert payload["roles"] == {"primary": "boy", "partner": "girl"}
    assert payload["primary"]["resolved_place"]["place_label"] == "Mumbai, Maharashtra, India"
    assert payload["partner"]["resolved_place"]["timezone"] == "Europe/London"

    compatibility = payload["compatibility"]
    ashta = compatibility["ashta_kuta"]
    assert ashta["max_score"] == 36.0
    assert len(ashta["components"]) == 8
    assert ashta["classification"] in {"Excellent", "Very Good", "Middling", "Inauspicious"}
    assert compatibility["manglik"]["max_score"] == 8.0
    assert compatibility["summary"]["guna_score_max"] == 36.0


def test_compatibility_compute_respects_primary_role_direction() -> None:
    client = TestClient(app)
    base_payload = {
        "primary": {
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Mumbai",
        },
        "partner": {
            "date_of_birth": "2001-09-09",
            "time_of_birth": "01:30",
            "place_of_birth": "London",
        },
    }

    response_boy = client.post(
        "/v1/compatibility/compute",
        json={**base_payload, "primary_role": "boy"},
    )
    response_girl = client.post(
        "/v1/compatibility/compute",
        json={**base_payload, "primary_role": "girl"},
    )

    assert response_boy.status_code == 200
    assert response_girl.status_code == 200

    score_boy = response_boy.json()["compatibility"]["ashta_kuta"]["total_score"]
    score_girl = response_girl.json()["compatibility"]["ashta_kuta"]["total_score"]
    assert score_boy != score_girl


def test_compatibility_compute_accepts_custom_place_payloads() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/compatibility/compute",
        json={
            "primary": {
                "date_of_birth": "1999-07-04",
                "time_of_birth": "12:22",
                "place_of_birth": "Custom One",
                "custom_place": {
                    "place_label": "Custom One, Testland",
                    "latitude": 19.076,
                    "longitude": 72.8777,
                    "timezone": "Asia/Kolkata",
                    "elevation_m": 14.0,
                },
            },
            "partner": {
                "date_of_birth": "2001-09-09",
                "time_of_birth": "01:30",
                "place_of_birth": "Custom Two",
                "custom_place": {
                    "place_label": "Custom Two, Testland",
                    "latitude": 40.7128,
                    "longitude": -74.006,
                    "timezone": "America/New_York",
                    "elevation_m": 10.0,
                },
            },
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["primary"]["resolved_place"]["place_label"] == "Custom One, Testland"
    assert payload["partner"]["resolved_place"]["place_label"] == "Custom Two, Testland"
