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
- `GET /v1/engine/parity/drik-suite` (strict parity on verified Drik fixtures)
- `GET /v1/engine/canonical-preview`
- `GET /v1/metadata/astrology-terms` (shared term contract for mobile/web)
- `GET /v1/places/search?query=<text>`
- `POST /v1/reports/compute` (recommended one-call endpoint for app clients)
- `POST /v1/charts/compute` (legacy-compatible chart-only endpoint)
- `POST /v1/dasha/compute` (legacy-compatible dasha-only endpoint)
- `POST /v1/engine/chart` (advanced/direct coordinates)
- `POST /v1/engine/chart-from-place` (legacy-compatible place flow)

## Mobile Integration (Recommended)

Use this endpoint from Flutter/mobile/web:

- `POST /v1/reports/compute`

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
curl -X POST "http://127.0.0.1:8000/v1/reports/compute" \
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
    "place_label": "Mumbai, Maharashtra, India",
    "latitude": 19.076,
    "longitude": 72.8777,
    "timezone": "Asia/Kolkata",
    "elevation_m": 14.0
  },
  "dasha": {
    "system": "Vimshottari",
    "current_maha_dasha": "Ketu",
    "current_antar_dasha": "Rahu",
    "maha_timeline": [],
    "antar_timeline_current_maha": []
  },
  "snapshot": {
    "meta": {
      "status": "computed"
    },
    "panchanga": {
      "tithi": {
        "name_vedic": "Krishna Shashthi",
        "name_english": "Waning Shashthi"
      },
      "vara": {
        "name_vedic": "Ravivara",
        "name_english": "Sunday"
      },
      "nakshatra": {
        "name_vedic": "P Bhadrapada",
        "pada": 1
      },
      "yoga": {
        "name_vedic": "Ayushman"
      },
      "karana": {
        "name_vedic": "Garija"
      },
      "sunrise": { "local_time": "06:03" },
      "sunset": { "local_time": "19:13" }
    },
    "varga": {
      "d1": { "lagna_rashi": "Kany" },
      "d9": { "lagna_rashi": "Maka" }
    },
    "graha_table": {
      "sun": {
        "rashi": "Mitu",
        "house": 10,
        "retrograde": false,
        "combust": false
      }
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

- Uses a global GeoNames city dataset (`cities500`, 2,20,000+ cities) for worldwide lookup.
- Uses GeoNames `admin1CodesASCII` mapping for global region/state labels (for example `City, State/Region, Country`).
- Keeps curated aliases (for example, `Bombay` -> `Mumbai, Maharashtra, India`) for compatibility.
- Falls back to external geocoding (Mapbox/Google/Nominatim) when a city is not in local index.

Data attribution: [GeoNames](https://www.geonames.org/) (cities and admin1 region codes).

### Optional Custom Place Payload

When the client already has precise coordinates + timezone, send `custom_place`
to bypass name resolution ambiguity:

```json
{
  "date_of_birth": "1999-07-04",
  "time_of_birth": "12:22",
  "place_of_birth": "Typed by user",
  "custom_place": {
    "place_label": "Custom City, Testland",
    "latitude": 19.076,
    "longitude": 72.8777,
    "timezone": "Asia/Kolkata",
    "elevation_m": 14.0
  }
}
```

### Geocoding Environment Variables

- `TRIKAAL_GEONAMES_MIN_CITY_POPULATION` default `500`.
- `TRIKAAL_ENABLE_FALLBACK_GEOCODING` default `1`.
- `TRIKAAL_PREFER_EXTERNAL_SEARCH` default `0` (set `1` to show Google/Mapbox/OSM suggestions first).
- `TRIKAAL_MAPBOX_ACCESS_TOKEN` optional (preferred fallback when set).
- `TRIKAAL_GOOGLE_MAPS_API_KEY` optional (fallback when set).
- `TRIKAAL_GEOCODER_PROVIDER` optional: `google` / `mapbox` / `nominatim` / `auto`.
- `TRIKAAL_NOMINATIM_EMAIL` optional (recommended for Nominatim policy).
- `TRIKAAL_GEOCODER_TIMEOUT_SECONDS` default `2.5`.

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

Now includes timeline fields:

- `current_maha_start` / `current_maha_end`
- `maha_timeline` (9 Mahadasha periods)
- `antar_timeline_current_maha` (9 Antardasha periods inside active Maha)

## Accuracy Lock (Drik Suite)

Use this endpoint to validate all Drik fixtures in one run and get aggregated
accuracy:

```bash
curl "http://127.0.0.1:8000/v1/engine/parity/drik-suite"
```

By default this endpoint runs only **verified** references (`drik_captured` and
`drik_archived_export`), which is what CI gate enforcement uses.

To include provisional engine-seed fixtures too:

```bash
curl "http://127.0.0.1:8000/v1/engine/parity/drik-suite?include_unverified=true"
```

Response includes:

- `available_fixture_count` (verified + provisional)
- `fixture_count`
- `verified_fixture_count`
- `unverified_fixture_count`
- `matched_fixture_count`
- `mismatched_fixture_count`
- `compared_field_count`
- `matched_field_count`
- `accuracy_percent`
- `fixtures[]` with per-fixture differences (if any)

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
