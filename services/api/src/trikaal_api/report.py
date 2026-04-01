from __future__ import annotations

import sys
from datetime import datetime
from typing import Any
from zoneinfo import ZoneInfo

from pydantic import BaseModel, Field

from trikaal_api.canonical import VEDIC_ENGINE_SRC
from trikaal_api.interpretation import build_interpretations
from trikaal_api.place_models import CustomPlaceInput
from trikaal_api.report_contract import (
    ComputeReportResponseContract,
    DailyTransitBriefContract,
    DashaContract,
    InterpretationsContract,
    SnapshotContract,
)
from trikaal_api.resolver import PlaceResolution, resolve_place
from trikaal_api.transit import build_daily_transit_brief

if str(VEDIC_ENGINE_SRC) not in sys.path:
    sys.path.insert(0, str(VEDIC_ENGINE_SRC))

from vedic_engine import (
    BirthEvent,
    CalculationProfile,
    compute_chart_snapshot,
    compute_vimshottari_dasha,
)


class ComputeReportRequest(BaseModel):
    date_of_birth: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    time_of_birth: str = Field(pattern=r"^\d{2}:\d{2}$")
    place_of_birth: str = Field(min_length=1)
    custom_place: CustomPlaceInput | None = None


class ComputeReportResponse(ComputeReportResponseContract):
    pass


def compute_report(request: ComputeReportRequest) -> ComputeReportResponse:
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
    snapshot = compute_chart_snapshot(
        birth_event=birth_event,
        profile=profile,
    )
    dasha = compute_vimshottari_dasha(
        birth_event=birth_event,
        profile=profile,
    )
    transit_local_dt = datetime.now(ZoneInfo(place.timezone))
    transit_event = BirthEvent(
        local_date=transit_local_dt.strftime("%Y-%m-%d"),
        local_time=transit_local_dt.strftime("%H:%M"),
        timezone=place.timezone,
        latitude=place.latitude,
        longitude=place.longitude,
        elevation_m=place.elevation_m,
        place_label=place.place_label,
    )
    transit_snapshot = compute_chart_snapshot(
        birth_event=transit_event,
        profile=profile,
    )
    snapshot_contract = SnapshotContract.model_validate(snapshot)
    transit_snapshot_contract = SnapshotContract.model_validate(transit_snapshot)
    dasha_contract = DashaContract.model_validate(dasha)
    interpretations_contract = InterpretationsContract.model_validate(
        build_interpretations(snapshot_contract)
    )
    daily_transit_contract = DailyTransitBriefContract.model_validate(
        build_daily_transit_brief(
            natal_snapshot=snapshot_contract,
            transit_snapshot=transit_snapshot_contract,
            as_of_local_iso=transit_local_dt.isoformat(timespec="minutes"),
            timezone=place.timezone,
        )
    )

    return ComputeReportResponse(
        profile=_profile_as_dict(profile),
        normalized_input={
            "local_date": request.date_of_birth,
            "local_time": request.time_of_birth,
            "place_query": " ".join(request.place_of_birth.split()),
        },
        resolved_place=_place_as_dict(place),
        snapshot=snapshot_contract,
        dasha=dasha_contract,
        interpretations=interpretations_contract,
        daily_transit=daily_transit_contract,
    )


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
