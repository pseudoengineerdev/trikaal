from fastapi.testclient import TestClient

from trikaal_api import resolver
from trikaal_api.geocoding import ExternalPlaceCandidate
from trikaal_api.main import app


def test_place_search_returns_mumbai_match() -> None:
    client = TestClient(app)
    response = client.get("/v1/places/search", params={"query": "mum"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["count"] >= 1
    assert payload["matches"][0]["place_label"] == "Mumbai, India"


def test_place_search_returns_empty_for_unknown_query() -> None:
    client = TestClient(app)
    response = client.get("/v1/places/search", params={"query": "zzzzzz"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["count"] == 0
    assert payload["matches"] == []


def test_place_search_returns_global_city_match() -> None:
    client = TestClient(app)
    response = client.get("/v1/places/search", params={"query": "london"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["count"] >= 1
    assert "London" in payload["matches"][0]["place_label"]


def test_place_search_prioritizes_curated_alias_match() -> None:
    client = TestClient(app)
    response = client.get("/v1/places/search", params={"query": "bombay"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["count"] >= 1
    assert payload["matches"][0]["place_label"] == "Mumbai, India"


def test_place_search_uses_external_fallback_when_enabled(monkeypatch) -> None:
    class _FakeGeocoder:
        def search_places(self, query: str, limit: int = 5) -> list[ExternalPlaceCandidate]:
            return [
                ExternalPlaceCandidate(
                    place_label="Zzyzx, United States",
                    latitude=35.0,
                    longitude=-116.0,
                    timezone="America/Los_Angeles",
                )
            ]

        def resolve_place(self, query: str) -> ExternalPlaceCandidate | None:
            return None

    monkeypatch.setenv("TRIKAAL_ENABLE_FALLBACK_GEOCODING", "1")
    resolver._fallback_search.cache_clear()
    monkeypatch.setattr(resolver, "_external_geocoder", lambda: _FakeGeocoder())

    client = TestClient(app)
    response = client.get("/v1/places/search", params={"query": "zzzzzz"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["count"] == 1
    assert payload["matches"][0]["place_label"] == "Zzyzx, United States"


def test_place_search_includes_state_for_same_name_us_cities() -> None:
    client = TestClient(app)
    response = client.get("/v1/places/search", params={"query": "pasadena"})

    assert response.status_code == 200
    payload = response.json()
    labels = [item["place_label"] for item in payload["matches"]]
    assert any("Pasadena, Texas, United States" == label for label in labels)
    assert any("Pasadena, California, United States" == label for label in labels)


def test_place_search_includes_region_for_non_us_cities() -> None:
    client = TestClient(app)
    response = client.get("/v1/places/search", params={"query": "london"})

    assert response.status_code == 200
    payload = response.json()
    labels = [item["place_label"] for item in payload["matches"]]
    assert any("London, England, United Kingdom" == label for label in labels)
    assert any("London, Ontario, Canada" == label for label in labels)


def test_place_search_can_prefer_external_results(monkeypatch) -> None:
    class _FakeGeocoder:
        def search_places(self, query: str, limit: int = 5) -> list[ExternalPlaceCandidate]:
            return [
                ExternalPlaceCandidate(
                    place_label="Pasadena, California, United States",
                    latitude=34.14778,
                    longitude=-118.14452,
                    timezone="America/Los_Angeles",
                )
            ]

        def resolve_place(self, query: str) -> ExternalPlaceCandidate | None:
            return None

    monkeypatch.setenv("TRIKAAL_ENABLE_FALLBACK_GEOCODING", "1")
    monkeypatch.setenv("TRIKAAL_PREFER_EXTERNAL_SEARCH", "1")
    resolver._fallback_search.cache_clear()
    monkeypatch.setattr(resolver, "_external_geocoder", lambda: _FakeGeocoder())

    client = TestClient(app)
    response = client.get("/v1/places/search", params={"query": "pasadena"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["count"] >= 1
    assert payload["matches"][0]["place_label"] == "Pasadena, California, United States"
