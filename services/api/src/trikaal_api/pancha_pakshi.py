from __future__ import annotations

import sys
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC
from trikaal_api.place_models import CustomPlaceInput
from trikaal_api.resolver import PlaceNotFoundError, PlaceResolution, resolve_place

if str(VEDIC_ENGINE_SRC) not in sys.path:
    sys.path.insert(0, str(VEDIC_ENGINE_SRC))

from vedic_engine import (
    BirthEvent,
    CalculationProfile,
    compute_pancha_pakshi_live,
)


class PanchaPakshiComputeRequest(BaseModel):
    date_of_birth: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    time_of_birth: str = Field(pattern=r"^\d{2}:\d{2}$")
    place_of_birth: str = Field(min_length=1)
    custom_place: CustomPlaceInput | None = None
    runtime_place_of_observation: str | None = Field(default=None, min_length=1)
    runtime_custom_place: CustomPlaceInput | None = None
    as_of_local_iso: datetime | None = None


class PanchaPakshiComputeResponse(BaseModel):
    profile: dict[str, Any]
    normalized_input: dict[str, str]
    resolved_place: dict[str, Any]
    pancha_pakshi: dict[str, Any]


def compute_pancha_pakshi(
    request: PanchaPakshiComputeRequest,
) -> PanchaPakshiComputeResponse:
    place = _resolve_place_input(
        place_query=request.place_of_birth,
        custom_place=request.custom_place,
    )
    profile = CalculationProfile()
    birth_event = BirthEvent(
        local_date=request.date_of_birth,
        local_time=request.time_of_birth,
        timezone=place.timezone,
        latitude=place.latitude,
        longitude=place.longitude,
        elevation_m=place.elevation_m,
        place_label=place.place_label,
    )
    runtime_place = _resolve_runtime_place_input(
        runtime_place_query=request.runtime_place_of_observation,
        runtime_custom_place=request.runtime_custom_place,
    )
    runtime_reference_event = None
    if runtime_place is not None:
        runtime_reference_event = BirthEvent(
            local_date=request.date_of_birth,
            local_time=request.time_of_birth,
            timezone=runtime_place.timezone,
            latitude=runtime_place.latitude,
            longitude=runtime_place.longitude,
            elevation_m=runtime_place.elevation_m,
            place_label=runtime_place.place_label,
        )

    pancha_pakshi = compute_pancha_pakshi_live(
        birth_event=birth_event,
        profile=profile,
        as_of=request.as_of_local_iso,
        runtime_reference_event=runtime_reference_event,
    )

    normalized_input: dict[str, str] = {
        "local_date": request.date_of_birth,
        "local_time": request.time_of_birth,
        "place_query": " ".join(request.place_of_birth.split()),
    }
    if request.as_of_local_iso is not None:
        normalized_input["as_of_local_iso"] = request.as_of_local_iso.isoformat()
    if request.runtime_place_of_observation is not None:
        normalized_input["runtime_place_of_observation"] = " ".join(
            request.runtime_place_of_observation.split()
        )

    return PanchaPakshiComputeResponse(
        profile={
            "profile_id": profile.profile_id,
            "zodiac_system": profile.zodiac_system,
            "ayanamsha": profile.ayanamsha,
            "calculation_method": profile.calculation_method,
        },
        normalized_input=normalized_input,
        resolved_place=_place_as_dict(place),
        pancha_pakshi=pancha_pakshi,
    )


def _place_as_dict(place: PlaceResolution) -> dict[str, Any]:
    return {
        "place_label": place.place_label,
        "latitude": place.latitude,
        "longitude": place.longitude,
        "timezone": place.timezone,
        "elevation_m": place.elevation_m,
    }


def _resolve_place_input(
    place_query: str,
    custom_place: CustomPlaceInput | None,
) -> PlaceResolution:
    if custom_place is not None:
        return custom_place.to_place_resolution()
    return resolve_place(place_query)


def _resolve_runtime_place_input(
    *,
    runtime_place_query: str | None,
    runtime_custom_place: CustomPlaceInput | None,
) -> PlaceResolution | None:
    if runtime_custom_place is not None:
        return runtime_custom_place.to_place_resolution()
    if runtime_place_query is None:
        return None
    cleaned = " ".join(runtime_place_query.split())
    if not cleaned:
        return None
    try:
        return resolve_place(cleaned)
    except PlaceNotFoundError:
        return None
