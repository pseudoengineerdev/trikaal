from fastapi import FastAPI

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
