from __future__ import annotations

import sys
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC
from trikaal_api.place_models import CustomPlaceInput
from trikaal_api.resolver import PlaceResolution, resolve_place

if str(VEDIC_ENGINE_SRC) not in sys.path:
    sys.path.insert(0, str(VEDIC_ENGINE_SRC))

from vedic_engine import (  # noqa: E402
    BirthEvent,
    CalculationProfile,
    compute_chart_snapshot,
    compute_kundali_compatibility,
)


class CompatibilityRole(str, Enum):
    boy = "boy"
    girl = "girl"


class CompatibilityPersonInput(BaseModel):
    date_of_birth: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    time_of_birth: str = Field(pattern=r"^\d{2}:\d{2}$")
    place_of_birth: str = Field(min_length=1)
    custom_place: CustomPlaceInput | None = None


class CompatibilityPersonResult(BaseModel):
    normalized_input: dict[str, str]
    resolved_place: dict[str, Any]
    snapshot: dict[str, Any]


class CompatibilityComputeRequest(BaseModel):
    primary: CompatibilityPersonInput
    partner: CompatibilityPersonInput
    primary_role: CompatibilityRole = CompatibilityRole.boy


class CompatibilityComputeResponse(BaseModel):
    profile: dict[str, str]
    roles: dict[str, str]
    primary: CompatibilityPersonResult
    partner: CompatibilityPersonResult
    compatibility: dict[str, Any]


def compute_compatibility(request: CompatibilityComputeRequest) -> CompatibilityComputeResponse:
    profile = CalculationProfile()

    primary_place = _resolve_place_input(
        place_query=request.primary.place_of_birth,
        custom_place=request.primary.custom_place,
    )
    partner_place = _resolve_place_input(
        place_query=request.partner.place_of_birth,
        custom_place=request.partner.custom_place,
    )

    primary_event = BirthEvent(
        local_date=request.primary.date_of_birth,
        local_time=request.primary.time_of_birth,
        timezone=primary_place.timezone,
        latitude=primary_place.latitude,
        longitude=primary_place.longitude,
        elevation_m=primary_place.elevation_m,
        place_label=primary_place.place_label,
    )
    partner_event = BirthEvent(
        local_date=request.partner.date_of_birth,
        local_time=request.partner.time_of_birth,
        timezone=partner_place.timezone,
        latitude=partner_place.latitude,
        longitude=partner_place.longitude,
        elevation_m=partner_place.elevation_m,
        place_label=partner_place.place_label,
    )

    primary_snapshot = compute_chart_snapshot(
        birth_event=primary_event,
        profile=profile,
    )
    partner_snapshot = compute_chart_snapshot(
        birth_event=partner_event,
        profile=profile,
    )

    if request.primary_role == CompatibilityRole.boy:
        boy_snapshot = primary_snapshot
        girl_snapshot = partner_snapshot
        partner_role = CompatibilityRole.girl
    else:
        boy_snapshot = partner_snapshot
        girl_snapshot = primary_snapshot
        partner_role = CompatibilityRole.boy

    compatibility = compute_kundali_compatibility(
        boy_snapshot=boy_snapshot,
        girl_snapshot=girl_snapshot,
    )

    return CompatibilityComputeResponse(
        profile=_profile_as_dict(profile),
        roles={
            "primary": request.primary_role.value,
            "partner": partner_role.value,
        },
        primary=CompatibilityPersonResult(
            normalized_input=_normalized_input(
                date_of_birth=request.primary.date_of_birth,
                time_of_birth=request.primary.time_of_birth,
                place_of_birth=request.primary.place_of_birth,
            ),
            resolved_place=_place_as_dict(primary_place),
            snapshot=primary_snapshot,
        ),
        partner=CompatibilityPersonResult(
            normalized_input=_normalized_input(
                date_of_birth=request.partner.date_of_birth,
                time_of_birth=request.partner.time_of_birth,
                place_of_birth=request.partner.place_of_birth,
            ),
            resolved_place=_place_as_dict(partner_place),
            snapshot=partner_snapshot,
        ),
        compatibility=compatibility,
    )


def _normalized_input(
    *,
    date_of_birth: str,
    time_of_birth: str,
    place_of_birth: str,
) -> dict[str, str]:
    return {
        "local_date": date_of_birth,
        "local_time": time_of_birth,
        "place_query": " ".join(place_of_birth.split()),
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
