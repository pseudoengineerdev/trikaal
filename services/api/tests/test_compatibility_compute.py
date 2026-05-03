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
    assert payload["profile"]["profile_id"] == "vedic_lahiri_v1"
    assert payload["roles"] == {"primary": "boy", "partner": "girl"}
    assert payload["primary"]["resolved_place"]["place_label"] == "Mumbai, Maharashtra, India"
    assert payload["partner"]["resolved_place"]["timezone"] == "Europe/London"

    compatibility = payload["compatibility"]
    ashta = compatibility["ashta_kuta"]
    assert ashta["max_score"] == 36.0
    assert len(ashta["components"]) == 8
    assert ashta["classification"] in {"Excellent", "Very Good", "Middling", "Inauspicious"}
    assert compatibility["manglik"]["max_score"] == 8.0
    assert compatibility["manglik"]["rule_profile_id"] == "mangal_dosha_v2"
    assert (
        compatibility["manglik"]["method"]
        == "mars_in_1_2_4_7_8_12_from_lagna_moon_venus_with_house_sign_exceptions"
    )
    assert compatibility["manglik"]["boy"]["trigger_houses"] == [1, 2, 4, 7, 8, 12]
    assert "reference_evidence" in compatibility["manglik"]["boy"]
    assert compatibility["summary"]["guna_score_max"] == 36.0


def test_compatibility_compute_sahil_candace_pdf_case_matches_36_with_custom_places() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/compatibility/compute",
        json={
            "primary": {
                "date_of_birth": "1999-07-04",
                "time_of_birth": "12:22",
                "place_of_birth": "Mumbai",
                "custom_place": {
                    "place_label": "Mumbai, Maharashtra, India",
                    "latitude": 19.0728,
                    "longitude": 72.8825,
                    "timezone": "Asia/Kolkata",
                    "elevation_m": 14.0,
                },
            },
            "partner": {
                "date_of_birth": "1993-02-22",
                "time_of_birth": "17:35",
                "place_of_birth": "Pasadena",
                "custom_place": {
                    "place_label": "Pasadena, Texas, United States",
                    "latitude": 29.6911,
                    "longitude": -95.2092,
                    "timezone": "America/Chicago",
                    "elevation_m": 12.0,
                },
            },
            "primary_role": "boy",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    compatibility = payload["compatibility"]
    ashta = compatibility["ashta_kuta"]
    assert ashta["total_score"] == 36.0
    assert {component["key"]: component["score"] for component in ashta["components"]} == {
        "varna": 1.0,
        "vashya": 2.0,
        "tara": 3.0,
        "yoni": 4.0,
        "graha_maitri": 5.0,
        "gana": 6.0,
        "bhakoot": 7.0,
        "nadi": 8.0,
    }
    assert compatibility["manglik"]["rule_profile_id"] == "mangal_dosha_v2"
    assert compatibility["manglik"]["pair_alignment"] == "Unbalanced"
    assert compatibility["manglik"]["boy"]["active_references"] == []
    assert compatibility["manglik"]["girl"]["active_references"] == ["venus"]
    assert compatibility["manglik"]["boy"]["cancelled_references"] == ["lagna"]
    assert compatibility["manglik"]["boy"]["dosha_percent"] == 0
    assert compatibility["manglik"]["boy"]["raw_dosha_percent"] == 150
    assert compatibility["manglik"]["girl"]["dosha_percent"] == 150
    assert (
        "Mars in Second House *considered by South astrologers"
        in compatibility["manglik"]["boy"]["dosha_reasons"]
    )
    assert (
        "Brihaspati 7th sight aspects Mangal"
        in compatibility["manglik"]["boy"]["nullification_reasons"]
    )
    assert (
        "Mars in Fourth House"
        in compatibility["manglik"]["girl"]["dosha_reasons"]
    )


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
