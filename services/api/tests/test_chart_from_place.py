from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_chart_from_place_endpoint_resolves_mumbai() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/engine/chart-from-place",
        json={
            "local_date": "1999-07-04",
            "local_time": "12:22",
            "place_query": "Mumbai",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["resolved_place"]["place_label"] == "Mumbai, India"
    assert payload["resolved_place"]["timezone"] == "Asia/Kolkata"
    assert payload["snapshot"]["vedic"]["lagna_rashi"] == "Kany"


def test_chart_from_place_endpoint_resolves_alias_bombay() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/engine/chart-from-place",
        json={
            "local_date": "1999-07-04",
            "local_time": "12:22",
            "place_query": "Bombay",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["resolved_place"]["place_label"] == "Mumbai, India"
    assert payload["resolved_place"]["timezone"] == "Asia/Kolkata"


def test_chart_from_place_endpoint_returns_not_found_for_unknown_city() -> None:
    client = TestClient(app)
    response = client.post(
        "/v1/engine/chart-from-place",
        json={
            "local_date": "1999-07-04",
            "local_time": "12:22",
            "place_query": "zzzzzzzzzz",
        },
    )

    assert response.status_code == 404
