from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel

WORKSPACE_ROOT = Path(__file__).resolve().parents[4]
TERMS_CONTRACT_PATH = WORKSPACE_ROOT / "libs" / "contracts" / "astrology_terms.v1.json"


class AstrologyTermsResponse(BaseModel):
    version: str
    rashi: dict[str, dict[str, str]]
    nakshatra: dict[str, dict[str, str]]
    graha: dict[str, dict[str, str]]


def load_astrology_terms() -> AstrologyTermsResponse:
    payload: dict[str, Any] = json.loads(TERMS_CONTRACT_PATH.read_text(encoding="utf-8"))
    return AstrologyTermsResponse.model_validate(payload)
