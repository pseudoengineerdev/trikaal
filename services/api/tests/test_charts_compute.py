from fastapi.testclient import TestClient

from trikaal_api import resolver
from trikaal_api.geocoding import ExternalPlaceCandidate
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
    assert payload["resolved_place"]["place_label"] == "Mumbai, Maharashtra, India"
    assert payload["snapshot"]["meta"]["status"] == "computed"
    assert payload["snapshot"]["vedic"]["sun_rashi"] == "Mitu"
    assert payload["snapshot"]["varga"]["d1"]["lagna_rashi"] == "Kany"
    assert payload["snapshot"]["varga"]["d9"]["lagna_rashi"]
    assert payload["snapshot"]["varga"]["d10"]["lagna_rashi"]
    assert payload["snapshot"]["varga"]["d60"]["lagna_rashi"]
    assert payload["snapshot"]["varga"]["d1"]["graha_positions"]["sun"]["rashi"] == "Mitu"
    assert payload["snapshot"]["varga"]["d9"]["graha_positions"]["sun"]["house"] >= 1
    assert payload["snapshot"]["varga"]["d60"]["graha_positions"]["lagna"]["rashi"]
    assert len([key for key in payload["snapshot"]["varga"] if key.startswith("d")]) == 60
    assert payload["snapshot"]["graha_table"]["sun"]["rashi"] == "Mitu"
    assert payload["snapshot"]["graha_table"]["sun"]["house"] == 10
    assert "retrograde" in payload["snapshot"]["graha_table"]["sun"]
    assert "combust" in payload["snapshot"]["graha_table"]["sun"]
    assert payload["snapshot"]["panchanga"]["vara"]["name_vedic"] == "Ravivara"
    assert payload["snapshot"]["panchanga"]["tithi"]["name_vedic"] == "Krishna Shashthi"
    assert payload["snapshot"]["panchanga"]["nakshatra"]["name_vedic"] == "P Bhadrapada"
    assert payload["snapshot"]["panchanga"]["yoga"]["name_vedic"] == "Ayushman"
    assert payload["snapshot"]["panchanga"]["karana"]["name_vedic"] == "Garija"
    assert isinstance(payload["snapshot"]["panchanga"]["sunrise"]["local_time"], str)
    assert isinstance(payload["snapshot"]["panchanga"]["sunset"]["local_time"], str)


def test_charts_compute_returns_not_found_for_unknown_place() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/charts/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "zzzzzzzzzz",
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


def test_charts_compute_accepts_custom_place_payload() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/charts/compute",
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


def test_charts_compute_uses_external_fallback_when_enabled(monkeypatch) -> None:
    class _FakeGeocoder:
        def search_places(self, query: str, limit: int = 5) -> list[ExternalPlaceCandidate]:
            return []

        def resolve_place(self, query: str) -> ExternalPlaceCandidate | None:
            return ExternalPlaceCandidate(
                place_label="Mystic City, Wonderland",
                latitude=19.076,
                longitude=72.8777,
                timezone="Asia/Kolkata",
            )

    monkeypatch.setenv("TRIKAAL_ENABLE_FALLBACK_GEOCODING", "1")
    resolver._fallback_resolve.cache_clear()
    monkeypatch.setattr(resolver, "_external_geocoder", lambda: _FakeGeocoder())

    client = TestClient(app)
    response = client.post(
        "/v1/charts/compute",
        json={
            "date_of_birth": "1999-07-04",
            "time_of_birth": "12:22",
            "place_of_birth": "rarecustomcity",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["resolved_place"]["place_label"] == "Mystic City, Wonderland"
