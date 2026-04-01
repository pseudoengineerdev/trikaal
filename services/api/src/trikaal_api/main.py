from zoneinfo import ZoneInfoNotFoundError

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from trikaal_api.canonical import CanonicalPreview, build_canonical_preview
from trikaal_api.chart import (
    ChartRequest,
    ChartResponse,
    ComputeChartRequest,
    ComputeChartResponse,
    PlaceChartRequest,
    PlaceChartResponse,
    compute_chart,
    generate_chart_snapshot,
    generate_chart_snapshot_from_place,
)
from trikaal_api.dasha import DashaComputeRequest, DashaComputeResponse, compute_dasha
from trikaal_api.metadata import AstrologyTermsResponse, load_astrology_terms
from trikaal_api.parity import (
    ParityResult,
    ParitySuiteResult,
    run_canonical_reference_parity_check,
    run_reference_parity_suite_check,
)
from trikaal_api.report import ComputeReportRequest, ComputeReportResponse, compute_report
from trikaal_api.resolver import PlaceNotFoundError, search_places

app = FastAPI(
    title="Trikaal API",
    version="0.1.0",
    summary="Backend API for Vedic astrology calculations and reports.",
)


class PlaceSearchResponse(BaseModel):
    query: str
    count: int
    matches: list[dict[str, str | float]]


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/v1/engine/parity/canonical-reference", response_model=ParityResult)
def canonical_reference_parity() -> ParityResult:
    return run_canonical_reference_parity_check()


@app.get("/v1/engine/parity/reference-suite", response_model=ParitySuiteResult)
def reference_suite_parity() -> ParitySuiteResult:
    return run_reference_parity_suite_check()


@app.get("/v1/engine/canonical-preview", response_model=CanonicalPreview)
def canonical_preview() -> CanonicalPreview:
    return build_canonical_preview()


@app.post("/v1/engine/chart", response_model=ChartResponse)
def chart(request: ChartRequest) -> ChartResponse:
    try:
        return generate_chart_snapshot(request)
    except ZoneInfoNotFoundError as exc:
        raise HTTPException(
            status_code=422,
            detail=f"Unknown timezone: {request.timezone}",
        ) from exc


@app.post("/v1/engine/chart-from-place", response_model=PlaceChartResponse)
def chart_from_place(request: PlaceChartRequest) -> PlaceChartResponse:
    try:
        return generate_chart_snapshot_from_place(request)
    except PlaceNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ZoneInfoNotFoundError as exc:
        raise HTTPException(status_code=422, detail=f"Unknown timezone: {exc}") from exc


@app.post("/v1/charts/compute", response_model=ComputeChartResponse)
def charts_compute(request: ComputeChartRequest) -> ComputeChartResponse:
    try:
        return compute_chart(request)
    except PlaceNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ZoneInfoNotFoundError as exc:
        raise HTTPException(status_code=422, detail=f"Unknown timezone: {exc}") from exc


@app.post("/v1/dasha/compute", response_model=DashaComputeResponse)
def dasha_compute(request: DashaComputeRequest) -> DashaComputeResponse:
    try:
        return compute_dasha(request)
    except PlaceNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ZoneInfoNotFoundError as exc:
        raise HTTPException(status_code=422, detail=f"Unknown timezone: {exc}") from exc


@app.post("/v1/reports/compute", response_model=ComputeReportResponse)
def reports_compute(request: ComputeReportRequest) -> ComputeReportResponse:
    try:
        return compute_report(request)
    except PlaceNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
    except ZoneInfoNotFoundError as exc:
        raise HTTPException(status_code=422, detail=f"Unknown timezone: {exc}") from exc


@app.get("/v1/places/search", response_model=PlaceSearchResponse)
def place_search(query: str) -> PlaceSearchResponse:
    matches = [
        {
            "place_label": place.place_label,
            "latitude": place.latitude,
            "longitude": place.longitude,
            "timezone": place.timezone,
            "elevation_m": place.elevation_m,
        }
        for place in search_places(query)
    ]
    return PlaceSearchResponse(query=query, count=len(matches), matches=matches)


@app.get("/v1/metadata/astrology-terms", response_model=AstrologyTermsResponse)
def astrology_terms() -> AstrologyTermsResponse:
    return load_astrology_terms()
