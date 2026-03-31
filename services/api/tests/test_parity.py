from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_canonical_drik_parity_check() -> None:
    client = TestClient(app)
    response = client.get("/v1/engine/parity/canonical-drik")

    assert response.status_code == 200
    payload = response.json()
    assert payload["fixture_id"] == "drik_mumbai_1999_07_04_1222_v1"
    assert payload["matched"] is True
    assert payload["difference_count"] == 0
    assert payload["differences"] == []
