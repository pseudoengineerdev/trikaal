from fastapi.testclient import TestClient

from trikaal_api.main import app

VADODARA_PLACE = {
    "place_label": "Vadodara, India",
    "latitude": 22.2994,
    "longitude": 73.2081,
    "timezone": "Asia/Kolkata",
    "elevation_m": 39.0,
}


def test_panchang_compute_returns_full_daily_payload() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/panchang/compute",
        json={
            "date": "2026-06-12",
            "place_of_birth": "Custom City",
            "custom_place": VADODARA_PLACE,
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["profile"]["profile_id"] == "vedic_lahiri_v1"
    assert payload["normalized_input"]["date"] == "2026-06-12"
    assert payload["resolved_place"]["place_label"] == "Vadodara, India"

    panchang = payload["panchang"]
    assert panchang["panchang_profile_id"] == "vedic_daily_panchang_v1"
    assert panchang["weekday"]["name_english"] == "Friday"
    assert panchang["tithi"][0]["name_vedic"] == "Krishna Dvadashi"
    assert panchang["tithi"][0]["end"]["local_time"] == "19:37"
    assert panchang["nakshatra"][0]["name_vedic"] == "Ashwini"
    assert panchang["lunar_month"]["amanta"] == "Jyeshtha (Adhika)"
    assert panchang["samvat"]["vikram"] == 2083
    assert panchang["samvat"]["shaka_samvatsara"] == "Parabhava"
    assert panchang["sun"]["sunrise"]["local_time"]
    assert panchang["auspicious"]["brahma_muhurta"]["start"]["local_time"]
    assert panchang["inauspicious"]["rahu_kalam"]["start"]["local_time"] == "10:56"
    assert len(panchang["advanced"]["hora_timeline"]) == 24
    assert len(panchang["advanced"]["choghadiya"]["day"]) == 8


def test_panchang_compute_rejects_malformed_date() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/panchang/compute",
        json={
            "date": "12-06-2026",
            "place_of_birth": "Mumbai",
        },
    )
    assert response.status_code == 422


def test_panchang_compute_rejects_impossible_date() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/panchang/compute",
        json={
            "date": "2026-02-31",
            "place_of_birth": "Custom City",
            "custom_place": VADODARA_PLACE,
        },
    )
    assert response.status_code == 400
