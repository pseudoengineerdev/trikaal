from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_reports_compute_returns_chart_and_dasha_in_one_response() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/reports/compute",
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
    assert payload["snapshot"]["meta"]["status"] == "computed"
    assert payload["dasha"]["system"] == "Vimshottari"
    assert payload["snapshot"]["panchanga"]["vara"]["name_vedic"] == "Ravivara"
    assert payload["snapshot"]["panchanga"]["tithi"]["name_vedic"] == "Krishna Shashthi"
    assert payload["snapshot"]["panchanga"]["nakshatra"]["name_vedic"] == "P Bhadrapada"
    assert payload["snapshot"]["panchanga"]["yoga"]["name_vedic"] == "Ayushman"
    assert payload["snapshot"]["panchanga"]["karana"]["name_vedic"] == "Garija"
    assert payload["snapshot"]["varga"]["d1"]["lagna_rashi"] == "Kany"
    assert payload["snapshot"]["varga"]["d10"]["lagna_rashi"]
    assert payload["snapshot"]["varga"]["d60"]["lagna_rashi"]
    assert payload["snapshot"]["varga"]["d1"]["graha_positions"]["sun"]["rashi"] == "Mitu"
    assert payload["snapshot"]["varga"]["d9"]["graha_positions"]["sun"]["house"] >= 1
    assert payload["snapshot"]["varga"]["d60"]["graha_positions"]["lagna"]["rashi"]
    assert len(payload["dasha"]["maha_timeline"]) == 9
    assert len(payload["dasha"]["antar_timeline_current_maha"]) == 9
    assert payload["interpretations"]["version"] == "v1"
    assert len(payload["interpretations"]["cards"]) >= 6
    assert any(card["category"] == "yoga" for card in payload["interpretations"]["cards"])
    assert any(
        card["category"] == "house_lord" for card in payload["interpretations"]["cards"]
    )
    assert any(card["category"] == "aspects" for card in payload["interpretations"]["cards"])
    first_card = payload["interpretations"]["cards"][0]
    assert "english" in first_card["title"]
    assert "vedic" in first_card["title"]
    assert "english" in first_card["impact"]
    assert first_card["evidence"]
    transit = payload["daily_transit"]
    assert transit["version"] == "v1"
    assert transit["timezone"] == "Asia/Kolkata"
    assert transit["cards"]
    assert len(transit["cards"]) == 3
    assert all("do_items" in card for card in transit["cards"])
    assert all("watch_items" in card for card in transit["cards"])


def test_reports_compute_returns_not_found_for_unknown_place() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/reports/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "zzzzzzzzzz",
        },
    )

    assert response.status_code == 404


def test_reports_compute_accepts_custom_place_payload() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/reports/compute",
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
    assert payload["snapshot"]["meta"]["status"] == "computed"
    assert payload["dasha"]["system"] == "Vimshottari"
    assert payload["interpretations"]["version"] == "v1"
    assert payload["daily_transit"]["version"] == "v1"


def test_reports_compute_succeeds_for_high_latitude_polar_birth() -> None:
    # Above the polar circles the chart must still compute (200) rather than
    # 500. The sun may not rise or set there, so the snapshot's sunrise/sunset
    # are null and the report contract must accept that.
    client = TestClient(app)
    response = client.post(
        "/v1/reports/compute",
        json={
            "date_of_birth": "2000-12-21",
            "time_of_birth": "12:00",
            "place_of_birth": "Tromso",
            "custom_place": {
                "place_label": "Tromso, Norway",
                "latitude": 69.65,
                "longitude": 18.96,
                "timezone": "Europe/Oslo",
                "elevation_m": 0.0,
            },
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["snapshot"]["meta"]["status"] == "computed"
    assert payload["snapshot"]["vedic"]["lagna_rashi"]
    assert payload["snapshot"]["panchanga"]["sunrise"] is None
    assert payload["snapshot"]["panchanga"]["sunset"] is None
