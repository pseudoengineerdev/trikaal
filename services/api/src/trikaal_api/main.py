from fastapi import FastAPI


app = FastAPI(
    title="Trikaal API",
    version="0.1.0",
    summary="Backend API for Vedic astrology calculations and reports.",
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
