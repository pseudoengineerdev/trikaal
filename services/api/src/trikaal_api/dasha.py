from __future__ import annotations

import sys
from typing import Any

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC
from trikaal_api.resolver import PlaceResolution, resolve_place

if str(VEDIC_ENGINE_SRC) not in sys.path:
    sys.path.insert(0, str(VEDIC_ENGINE_SRC))

from vedic_engine import BirthEvent, CalculationProfile, compute_vimshottari_dasha


class DashaComputeRequest(BaseModel):
    date_of_birth: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    time_of_birth: str = Field(pattern=r"^\d{2}:\d{2}$")
    place_of_birth: str = Field(min_length=1)


class DashaComputeResponse(BaseModel):
    profile: dict[str, Any]
    normalized_input: dict[str, str]
    resolved_place: dict[str, Any]
    dasha: dict[str, Any]


def compute_dasha(request: DashaComputeRequest) -> DashaComputeResponse:
    place = resolve_place(request.place_of_birth)
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
    dasha = compute_vimshottari_dasha(
        birth_event=birth_event,
        profile=profile,
    )

    return DashaComputeResponse(
        profile={
            "profile_id": profile.profile_id,
            "zodiac_system": profile.zodiac_system,
            "ayanamsha": profile.ayanamsha,
            "calculation_method": profile.calculation_method,
        },
        normalized_input={
            "local_date": request.date_of_birth,
            "local_time": request.time_of_birth,
            "place_query": " ".join(request.place_of_birth.split()),
        },
        resolved_place=_place_as_dict(place),
        dasha=dasha,
    )


def _place_as_dict(place: PlaceResolution) -> dict[str, Any]:
    return {
        "place_label": place.place_label,
        "latitude": place.latitude,
        "longitude": place.longitude,
        "timezone": place.timezone,
        "elevation_m": place.elevation_m,
    }
