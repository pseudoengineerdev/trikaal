from fastapi.testclient import TestClient

from trikaal_api.interpretation import _aspected_houses, build_interpretations
from trikaal_api.main import app
from trikaal_api.report_contract import SnapshotContract


def test_aspected_houses_match_classical_offsets() -> None:
    assert _aspected_houses(1, "mangal") == [4, 7, 8]
    assert _aspected_houses(1, "guru") == [5, 7, 9]
    assert _aspected_houses(1, "shani") == [3, 7, 10]
    assert _aspected_houses(1, "sun") == [7]


def test_build_interpretations_returns_localized_cards() -> None:
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
    snapshot = SnapshotContract.model_validate(response.json()["snapshot"])

    interpretations = build_interpretations(snapshot)
    assert interpretations["version"] == "v1"
    cards = interpretations["cards"]
    assert cards
    assert any(card["category"] == "yoga" for card in cards)
    assert any(card["category"] == "house_lord" for card in cards)
    assert any(card["category"] == "aspects" for card in cards)

    first_card = cards[0]
    assert "english" in first_card["title"]
    assert "vedic" in first_card["title"]
    assert first_card["evidence"]
