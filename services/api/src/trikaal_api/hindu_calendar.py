from __future__ import annotations

from typing import Any, Literal

import sys

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC
from trikaal_api.place_models import CustomPlaceInput
from trikaal_api.resolver import PlaceResolution, resolve_place

if str(VEDIC_ENGINE_SRC) not in sys.path:
    sys.path.insert(0, str(VEDIC_ENGINE_SRC))

from vedic_engine import CalculationProfile, compute_hindu_calendar_month  # noqa: E402


MonthType = Literal["purnimanta", "amanta"]


class HinduCalendarComputeRequest(BaseModel):
    year: int = Field(ge=1, le=9999)
    month: int = Field(ge=1, le=12)
    month_type: MonthType = "purnimanta"
    place_of_birth: str = Field(min_length=1)
    custom_place: CustomPlaceInput | None = None


class HinduCalendarComputeResponse(BaseModel):
    profile: dict[str, str]
    normalized_input: dict[str, str]
    resolved_place: dict[str, Any]
    calendar: dict[str, Any]


def compute_hindu_calendar(
    request: HinduCalendarComputeRequest,
) -> HinduCalendarComputeResponse:
    profile = CalculationProfile()
    place = _resolve_place_input(
        place_query=request.place_of_birth,
        custom_place=request.custom_place,
    )
    calendar_payload = compute_hindu_calendar_month(
        year=request.year,
        month=request.month,
        timezone=place.timezone,
        latitude=place.latitude,
        longitude=place.longitude,
        elevation_m=place.elevation_m,
        month_type=request.month_type,
    )
    return HinduCalendarComputeResponse(
        profile=_profile_as_dict(profile),
        normalized_input=_normalized_input(
            year=request.year,
            month=request.month,
            month_type=request.month_type,
            place_of_birth=request.place_of_birth,
        ),
        resolved_place=_place_as_dict(place),
        calendar=calendar_payload,
    )


def _normalized_input(
    *,
    year: int,
    month: int,
    month_type: MonthType,
    place_of_birth: str,
) -> dict[str, str]:
    return {
        "year": str(year),
        "month": str(month),
        "place_query": " ".join(place_of_birth.split()),
        "month_type": month_type,
    }

def _profile_as_dict(profile: CalculationProfile) -> dict[str, str]:
    return {
        "profile_id": profile.profile_id,
        "zodiac_system": profile.zodiac_system,
        "ayanamsha": profile.ayanamsha,
        "calculation_method": profile.calculation_method,
    }


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
