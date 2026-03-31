from __future__ import annotations

import sys
from typing import Any

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC

if str(VEDIC_ENGINE_SRC) not in sys.path:
    sys.path.insert(0, str(VEDIC_ENGINE_SRC))

from vedic_engine import BirthEvent, CalculationProfile, compute_chart_snapshot


class ChartRequest(BaseModel):
    local_date: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    local_time: str = Field(pattern=r"^\d{2}:\d{2}$")
    timezone: str
    latitude: float = Field(ge=-90.0, le=90.0)
    longitude: float = Field(ge=-180.0, le=180.0)
    elevation_m: float
    place_label: str = Field(min_length=1)


class ChartResponse(BaseModel):
    profile: dict[str, Any]
    input: dict[str, Any]
    snapshot: dict[str, Any]


def generate_chart_snapshot(request: ChartRequest) -> ChartResponse:
    profile = CalculationProfile()
    birth_event = BirthEvent(
        local_date=request.local_date,
        local_time=request.local_time,
        timezone=request.timezone,
        latitude=request.latitude,
        longitude=request.longitude,
        elevation_m=request.elevation_m,
        place_label=request.place_label,
    )
    snapshot = compute_chart_snapshot(birth_event=birth_event, profile=profile)

    return ChartResponse(
        profile={
            "profile_id": profile.profile_id,
            "zodiac_system": profile.zodiac_system,
            "ayanamsha": profile.ayanamsha,
            "calculation_method": profile.calculation_method,
        },
        input=request.model_dump(),
        snapshot=snapshot,
    )
