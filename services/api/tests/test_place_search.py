from fastapi.testclient import TestClient

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
