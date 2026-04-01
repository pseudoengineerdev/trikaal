# API Service

Shared backend for mobile and web clients.

## Stack

- Python 3.12+
- FastAPI
- Uvicorn
- Pytest

## Local Setup

```bash
cd services/api
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

## Run

```bash
cd services/api
source .venv/bin/activate
uvicorn trikaal_api.main:app --reload
```

## Endpoints (Current)

- `GET /health`
- `GET /v1/engine/parity/canonical-drik`
- `GET /v1/engine/canonical-preview`
- `GET /v1/metadata/astrology-terms` (shared term contract for mobile/web)
- `GET /v1/places/search?query=<text>`
- `POST /v1/charts/compute` (recommended for app clients)
- `POST /v1/dasha/compute` (Vimshottari current dasha)
- `POST /v1/engine/chart` (advanced/direct coordinates)
- `POST /v1/engine/chart-from-place` (legacy-compatible place flow)

## Mobile Integration (Recommended)

Use this endpoint from Flutter:

- `POST /v1/charts/compute`

Request body:

```json
{
  "date_of_birth": "1999-07-04",
  "time_of_birth": "12:22",
  "place_of_birth": "Mumbai"
}
```

Example `curl`:

```bash
curl -X POST "http://127.0.0.1:8000/v1/charts/compute" \
  -H "Content-Type: application/json" \
  -d '{
    "date_of_birth": "1999-07-04",
    "time_of_birth": "12:22",
    "place_of_birth": "Mumbai"
  }'
```

Response shape (trimmed):

```json
{
  "profile": {
    "profile_id": "vedic_drik_lahiri_v1",
    "zodiac_system": "sidereal",
    "ayanamsha": "lahiri_chitrapaksha",
    "calculation_method": "drik_ganita"
  },
  "normalized_input": {
    "local_date": "1999-07-04",
    "local_time": "12:22",
    "place_query": "Mumbai"
  },
  "resolved_place": {
    "place_label": "Mumbai, India",
    "latitude": 19.076,
    "longitude": 72.8777,
    "timezone": "Asia/Kolkata",
    "elevation_m": 14.0
  },
  "snapshot": {
    "meta": {
      "status": "computed"
    }
  }
}
```

## Place Search (Autocomplete Helper)

Use this for city autocomplete in Flutter before compute:

```bash
curl "http://127.0.0.1:8000/v1/places/search?query=mum"
```

Resolver behavior:

- Uses a global city dataset (30k+ cities) for worldwide lookup.
- Keeps curated aliases (for example, `Bombay` -> `Mumbai, India`) for compatibility.

## Dasha Compute

Use this for current Vimshottari dasha calculation:

```bash
curl -X POST "http://127.0.0.1:8000/v1/dasha/compute" \
  -H "Content-Type: application/json" \
  -d '{
    "date_of_birth": "1999-07-04",
    "time_of_birth": "12:22",
    "place_of_birth": "Mumbai"
  }'
```

## Shared Terminology Contract

Use this endpoint so all clients (Flutter now, Next.js later) use one source of truth:

```bash
curl "http://127.0.0.1:8000/v1/metadata/astrology-terms"
```

Source file in repo:

- `libs/contracts/astrology_terms.v1.json`

## Test

```bash
cd services/api
source .venv/bin/activate
pytest
```
