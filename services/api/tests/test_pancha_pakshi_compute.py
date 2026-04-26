from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_pancha_pakshi_compute_returns_live_activity_payload() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/pancha-pakshi/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Mumbai",
            "as_of_local_iso": "2026-04-08T18:00:00+05:30",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["profile"]["profile_id"] == "vedic_drik_lahiri_v1"
    assert payload["resolved_place"]["place_label"] == "Mumbai, Maharashtra, India"
    assert payload["pancha_pakshi"]["version"] == "v1"
    assert payload["pancha_pakshi"]["birth"]["pakshi"] == "Vulture"
    assert payload["pancha_pakshi"]["runtime"]["phase"] in {"day", "night"}
    assert len(payload["pancha_pakshi"]["timeline"]) == 10
    assert payload["pancha_pakshi"]["active"]["sub_activity"]["activity"]


def test_pancha_pakshi_compute_returns_not_found_for_unknown_place() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/pancha-pakshi/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "zzzzzzzzzz",
        },
    )

    assert response.status_code == 404


def test_pancha_pakshi_compute_accepts_custom_place_payload() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/pancha-pakshi/compute",
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
    assert payload["pancha_pakshi"]["birth"]["pakshi"] == "Vulture"


def test_pancha_pakshi_compute_uses_runtime_place_for_live_window() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/pancha-pakshi/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Mumbai",
            "runtime_place_of_observation": "Detroit",
            "as_of_local_iso": "2026-04-08T09:00:00-04:00",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["pancha_pakshi"]["birth"]["pakshi"] == "Vulture"
    assert payload["pancha_pakshi"]["runtime"]["reference_timezone"] == "America/Detroit"
    assert "Detroit" in payload["pancha_pakshi"]["runtime"]["reference_place_label"]


def test_pancha_pakshi_compute_falls_back_when_runtime_place_not_found() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/pancha-pakshi/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "Mumbai",
            "runtime_place_of_observation": "zzzzzzzzzz",
            "as_of_local_iso": "2026-04-08T18:00:00+05:30",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["pancha_pakshi"]["runtime"]["reference_timezone"] == "Asia/Kolkata"
    assert "Mumbai" in payload["pancha_pakshi"]["runtime"]["reference_place_label"]
