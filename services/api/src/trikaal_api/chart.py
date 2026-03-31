from __future__ import annotations

import sys
from typing import Any
from zoneinfo import ZoneInfo

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC

if str(VEDIC_ENGINE_SRC) not in sys.path:
    sys.path.insert(0, str(VEDIC_ENGINE_SRC))

from vedic_engine import BirthEvent, CalculationProfile, compute_chart_snapshot

from trikaal_api.resolver import PlaceResolution, resolve_place


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


class PlaceChartRequest(BaseModel):
    local_date: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    local_time: str = Field(pattern=r"^\d{2}:\d{2}$")
    place_query: str = Field(min_length=1)


class PlaceChartResponse(BaseModel):
    profile: dict[str, Any]
    input: dict[str, Any]
    resolved_place: dict[str, Any]
    snapshot: dict[str, Any]


def generate_chart_snapshot(request: ChartRequest) -> ChartResponse:
    _ensure_timezone_exists(request.timezone)

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


def generate_chart_snapshot_from_place(request: PlaceChartRequest) -> PlaceChartResponse:
    place = resolve_place(request.place_query)
    chart_request = ChartRequest(
        local_date=request.local_date,
        local_time=request.local_time,
        timezone=place.timezone,
        latitude=place.latitude,
        longitude=place.longitude,
        elevation_m=place.elevation_m,
        place_label=place.place_label,
    )
    chart_response = generate_chart_snapshot(chart_request)

    return PlaceChartResponse(
        profile=chart_response.profile,
        input=request.model_dump(),
        resolved_place=_place_as_dict(place),
        snapshot=chart_response.snapshot,
    )


def _ensure_timezone_exists(timezone_name: str) -> None:
    ZoneInfo(timezone_name)


def _place_as_dict(place: PlaceResolution) -> dict[str, Any]:
    return {
        "place_label": place.place_label,
        "latitude": place.latitude,
        "longitude": place.longitude,
        "timezone": place.timezone,
        "elevation_m": place.elevation_m,
    }
