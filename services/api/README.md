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
- `GET /v1/engine/parity/canonical-reference`
- `GET /v1/engine/canonical-preview`

## Test

```bash
cd services/api
source .venv/bin/activate
pytest
```
