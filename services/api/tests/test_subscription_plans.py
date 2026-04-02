from fastapi.testclient import TestClient

from trikaal_api.main import app


def test_subscription_plans_endpoint_returns_shared_contract() -> None:
    client = TestClient(app)
    response = client.get("/v1/billing/plans")

    assert response.status_code == 200
    payload = response.json()
    assert payload["version"] == "v1"
    assert payload["currency"] == "USD"
    assert payload["default_plan_code"] == "monthly"
    plans = payload["plans"]
    assert len(plans) == 3

    weekly = next(plan for plan in plans if plan["code"] == "weekly")
    monthly = next(plan for plan in plans if plan["code"] == "monthly")
    yearly = next(plan for plan in plans if plan["code"] == "yearly")

    assert weekly["price_usd"] == 2.0
    assert weekly["discount_percent"] == 0
    assert monthly["price_usd"] == 5.0
    assert monthly["discount_percent"] == 38
    assert yearly["price_usd"] == 50.0
    assert yearly["discount_percent"] == 52
