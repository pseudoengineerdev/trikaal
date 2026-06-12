from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_hindu_calendar_compute_returns_calendar_for_simple_month_request() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/hindu-calendar/compute",
        json={
            "year": 2026,
            "month": 5,
            "month_type": "purnimanta",
            "place_of_birth": "Mumbai",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["profile"]["profile_id"] == "vedic_lahiri_v1"
    assert payload["normalized_input"]["year"] == "2026"
    assert payload["normalized_input"]["month"] == "5"
    assert payload["calendar"]["month_type"] == "purnimanta"
    assert payload["calendar"]["gregorian_month_label"] == "May 2026"
    assert payload["calendar"]["day_count"] >= 28
    assert payload["calendar"]["days"]
    first_day = payload["calendar"]["days"][0]
    assert first_day["paksha"] in {"Shukla", "Krishna"}
    assert "lunar_month_name" in first_day
    assert "tithi_name_vedic" in first_day
    assert "sunset_local_time" in first_day
    assert "nakshatra_name" in first_day
    assert first_day["nakshatra_number"] >= 1
    assert "selected_date" in payload["calendar"]
    assert payload["calendar"]["selected_day"]["lunar_day_of_month"] >= 1


def test_hindu_calendar_compute_accepts_custom_place_payload() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/hindu-calendar/compute",
        json={
            "year": 2026,
            "month": 5,
            "month_type": "amanta",
            "place_of_birth": "Custom City",
            "custom_place": {
                "place_label": "Detroit, United States",
                "latitude": 42.3314,
                "longitude": -83.0457,
                "timezone": "America/Detroit",
                "elevation_m": 191.0,
            },
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["resolved_place"]["place_label"] == "Detroit, United States"
    assert payload["calendar"]["month_type"] == "amanta"
    assert payload["calendar"]["month"] == 5
    assert payload["calendar"]["selected_day"]


def test_hindu_calendar_compute_uses_local_sunrise_for_detroit_june_transitions() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/hindu-calendar/compute",
        json={
            "year": 2026,
            "month": 6,
            "month_type": "amanta",
            "place_of_birth": "Detroit, United States",
            "custom_place": {
                "place_label": "Detroit, United States",
                "latitude": 42.3314,
                "longitude": -83.0458,
                "timezone": "America/Detroit",
                "elevation_m": 183.0,
            },
        },
    )

    assert response.status_code == 200
    payload = response.json()
    day14 = next(day for day in payload["calendar"]["days"] if day["day"] == 14)
    assert day14["sunrise_local_time"] == "06:00"
    assert day14["sunset_local_time"] == "21:04"
    assert day14["tithi_number"] == 30
    assert day14["lunar_day_of_month"] == 30
    assert day14["tithi_name_vedic"] == "Amavasya"

    day21 = next(day for day in payload["calendar"]["days"] if day["day"] == 21)
    assert day21["sunrise_local_time"] == "06:00"
    assert day21["sunset_local_time"] == "21:07"
    assert day21["tithi_number"] == 8
    assert day21["lunar_day_of_month"] == 8
    assert day21["tithi_name_vedic"] == "Shukla Ashtami"


def test_hindu_calendar_compute_marks_adhika_month_in_purnimanta() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/hindu-calendar/compute",
        json={
            "year": 2026,
            "month": 6,
            "month_type": "purnimanta",
            "place_of_birth": "Detroit, United States",
            "custom_place": {
                "place_label": "Detroit, United States",
                "latitude": 42.3314,
                "longitude": -83.0458,
                "timezone": "America/Detroit",
                "elevation_m": 183.0,
            },
        },
    )

    assert response.status_code == 200
    payload = response.json()
    day13 = next(day for day in payload["calendar"]["days"] if day["day"] == 13)
    assert "Adhika" in day13["lunar_month_name"]
    assert day13["lunar_day_of_month"] == 28

    day14 = next(day for day in payload["calendar"]["days"] if day["day"] == 14)
    assert "Adhika" in day14["lunar_month_name"]
    assert day14["lunar_day_of_month"] == 30

    day15 = next(day for day in payload["calendar"]["days"] if day["day"] == 15)
    assert day15["lunar_month_name"] == "Jyeshtha"
    assert day15["lunar_day_of_month"] == 16

    day30 = next(day for day in payload["calendar"]["days"] if day["day"] == 30)
    assert day30["lunar_month_name"] == "Ashadha"
    assert day30["lunar_day_of_month"] == 1


def test_hindu_calendar_compute_alias_route_keeps_working() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/hindu-calender/compute",
        json={
            "year": 2026,
            "month": 5,
            "month_type": "amanta",
            "place_of_birth": "Mumbai",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["calendar"]["month_type"] == "amanta"


def test_hindu_calendar_compute_rejects_invalid_month() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/hindu-calendar/compute",
        json={
            "year": 2026,
            "month": 13,
            "month_type": "purnimanta",
            "place_of_birth": "Mumbai",
        },
    )

    assert response.status_code == 422
