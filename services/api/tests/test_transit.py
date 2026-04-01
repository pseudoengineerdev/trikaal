from fastapi.testclient import TestClient

from trikaal_api.main import app
from trikaal_api.report_contract import SnapshotContract
from trikaal_api.transit import _house_from_lagna, build_daily_transit_brief


def test_house_from_lagna_handles_aliases() -> None:
    assert _house_from_lagna(lagna_rashi="Kany", transit_rashi="Mith") == 10
    assert _house_from_lagna(lagna_rashi="Kany", transit_rashi="Mitu") == 10
    assert _house_from_lagna(lagna_rashi="Kany", transit_rashi="Makar") == 5
    assert _house_from_lagna(lagna_rashi="Kany", transit_rashi="Maka") == 5


def test_build_daily_transit_brief_returns_expected_shape() -> None:
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

    brief = build_daily_transit_brief(
        natal_snapshot=snapshot,
        transit_snapshot=snapshot,
        as_of_local_iso="2026-04-01T09:15+05:30",
        timezone="Asia/Kolkata",
    )
    assert brief["version"] == "v1"
    assert brief["as_of_local_iso"] == "2026-04-01T09:15+05:30"
    assert brief["timezone"] == "Asia/Kolkata"
    assert len(brief["cards"]) == 3
    first = brief["cards"][0]
    assert first["card_id"].startswith("daily_transit_")
    assert first["do_items"]
    assert first["watch_items"]
