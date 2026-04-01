from __future__ import annotations

import sys
from typing import Any
from zoneinfo import ZoneInfo

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC
from trikaal_api.place_models import CustomPlaceInput

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
    custom_place: CustomPlaceInput | None = None


class PlaceChartResponse(BaseModel):
    profile: dict[str, Any]
    input: dict[str, Any]
    resolved_place: dict[str, Any]
    snapshot: dict[str, Any]


class ComputeChartRequest(BaseModel):
    date_of_birth: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    time_of_birth: str = Field(pattern=r"^\d{2}:\d{2}$")
    place_of_birth: str = Field(min_length=1)
    custom_place: CustomPlaceInput | None = None


class ComputeChartResponse(BaseModel):
    profile: dict[str, Any]
    normalized_input: dict[str, str]
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
    place = _resolve_place_input(
        place_query=request.place_query,
        custom_place=request.custom_place,
    )
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


def compute_chart(request: ComputeChartRequest) -> ComputeChartResponse:
    place_request = PlaceChartRequest(
        local_date=request.date_of_birth,
        local_time=request.time_of_birth,
        place_query=request.place_of_birth,
        custom_place=request.custom_place,
    )
    place_response = generate_chart_snapshot_from_place(place_request)

    return ComputeChartResponse(
        profile=place_response.profile,
        normalized_input={
            "local_date": place_request.local_date,
            "local_time": place_request.local_time,
            "place_query": " ".join(place_request.place_query.split()),
        },
        resolved_place=place_response.resolved_place,
        snapshot=place_response.snapshot,
    )


def _ensure_timezone_exists(timezone_name: str) -> None:
    ZoneInfo(timezone_name)


def _resolve_place_input(
    place_query: str,
    custom_place: CustomPlaceInput | None,
) -> PlaceResolution:
    if custom_place is not None:
        return custom_place.to_place_resolution()
    return resolve_place(place_query)


def _place_as_dict(place: PlaceResolution) -> dict[str, Any]:
    return {
        "place_label": place.place_label,
        "latitude": place.latitude,
        "longitude": place.longitude,
        "timezone": place.timezone,
        "elevation_m": place.elevation_m,
    }
