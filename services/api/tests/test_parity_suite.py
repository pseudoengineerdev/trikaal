from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_drik_suite_parity_check_reports_full_accuracy() -> None:
    client = TestClient(app)
    response = client.get("/v1/engine/parity/drik-suite")

    assert response.status_code == 200
    payload = response.json()

    assert payload["include_unverified"] is False
    assert payload["available_fixture_count"] >= 9
    assert payload["fixture_count"] >= 3
    assert payload["verified_fixture_count"] >= 3
    assert payload["unverified_fixture_count"] >= 6
    assert payload["all_matched"] is True
    assert payload["mismatched_fixture_count"] == 0
    assert payload["compared_field_count"] >= 150
    assert payload["matched_field_count"] == payload["compared_field_count"]
    assert payload["accuracy_percent"] == 100.0
    assert all(item["matched"] for item in payload["fixtures"])
    assert all(item["difference_count"] == 0 for item in payload["fixtures"])

    fixtures = {item["fixture_id"]: item for item in payload["fixtures"]}
    canonical = fixtures["drik_mumbai_1999_07_04_1222_v1"]
    assert canonical["compared_field_count"] >= 67
    assert canonical["verified_reference"] is True
    assert canonical["reference_status"] == "drik_captured"


def test_drik_suite_can_include_unverified_seed_cases() -> None:
    client = TestClient(app)
    response = client.get("/v1/engine/parity/drik-suite?include_unverified=true")

    assert response.status_code == 200
    payload = response.json()

    assert payload["include_unverified"] is True
    assert payload["fixture_count"] == payload["available_fixture_count"]
    assert payload["fixture_count"] >= 9
    assert payload["compared_field_count"] >= 260
    assert payload["all_matched"] is True
    assert any(item["verified_reference"] is False for item in payload["fixtures"])
