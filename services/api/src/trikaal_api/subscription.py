from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel

WORKSPACE_ROOT = Path(__file__).resolve().parents[4]
SUBSCRIPTION_CONTRACT_PATH = (
    WORKSPACE_ROOT / "libs" / "contracts" / "subscription_plans.v1.json"
)


class SubscriptionPlan(BaseModel):
    code: str
    cycle: str
    title: str
    price_usd: float
    period_label: str
    discount_percent: int
    discount_label: str | None
    badge: str | None
    recommended: bool


class SubscriptionPlansResponse(BaseModel):
    version: str
    currency: str
    headline: str
    subheadline: str
    default_plan_code: str
    plans: list[SubscriptionPlan]


def load_subscription_plans() -> SubscriptionPlansResponse:
    payload: dict[str, Any] = json.loads(
        SUBSCRIPTION_CONTRACT_PATH.read_text(encoding="utf-8")
    )
    return SubscriptionPlansResponse.model_validate(payload)
