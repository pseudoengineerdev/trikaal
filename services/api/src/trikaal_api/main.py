from fastapi import FastAPI

from trikaal_api.canonical import CanonicalPreview, build_canonical_preview
from trikaal_api.chart import ChartRequest, ChartResponse, generate_chart_snapshot
from trikaal_api.parity import ParityResult, run_canonical_reference_parity_check


app = FastAPI(
    title="Trikaal API",
    version="0.1.0",
    summary="Backend API for Vedic astrology calculations and reports.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/v1/engine/parity/canonical-reference", response_model=ParityResult)
def canonical_reference_parity() -> ParityResult:
    return run_canonical_reference_parity_check()


@app.get("/v1/engine/canonical-preview", response_model=CanonicalPreview)
def canonical_preview() -> CanonicalPreview:
    return build_canonical_preview()


@app.post("/v1/engine/chart", response_model=ChartResponse)
def chart(request: ChartRequest) -> ChartResponse:
    return generate_chart_snapshot(request)
