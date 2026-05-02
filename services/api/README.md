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
uvicorn trikaal_api.main:app --reload \
  --reload-dir src \
  --reload-dir ../../libs/vedic-engine/src
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
- `POST /v1/pancha-pakshi/compute` (realtime Pancha Pakshi timeline + active window)
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
  "interpretations": {
    "version": "v1",
    "cards": [
      {
        "card_id": "yoga_budha_aditya",
        "category": "yoga",
        "confidence": "high",
        "strength_score": 0.86,
        "title": {
          "english": "Budha-Aditya Yoga pattern detected",
          "vedic": "Budha-Aditya yoga pattern detected"
        },
        "summary": {
          "english": "Sun and Mercury are in the same house.",
          "vedic": "Surya and Budha are in the same bhava."
        },
        "impact": {
          "english": "This can support clear expression and planning.",
          "vedic": "This can support buddhi and articulate speech."
        },
        "evidence": [
          {
            "english": "Sun and Mercury both occupy H10.",
            "vedic": "Surya and Budha both occupy 10th Bhava."
          }
        ]
      }
    ]
  },
  "daily_transit": {
    "version": "v1",
    "as_of_local_iso": "2026-04-01T09:15+05:30",
    "timezone": "Asia/Kolkata",
    "cards": [
      {
        "card_id": "daily_transit_moon",
        "transit_graha_key": "moon",
        "transit_house_from_lagna": 6,
        "transit_rashi": "Kumb",
        "focus_tag": "Emotions",
        "title": {
          "english": "Transit Moon focus for today",
          "vedic": "Daily Chandra transit focus"
        },
        "summary": {
          "english": "Transit Moon is in H6 today.",
          "vedic": "Transit Chandra is in 6th Bhava today."
        },
        "do_items": [{ "english": "Review emotional decisions after one day.", "vedic": "Review emotional decisions after one day." }],
        "watch_items": [{ "english": "Avoid overreaction to temporary mood shifts.", "vedic": "Avoid overreaction to temporary mood shifts." }]
      }
    ]
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
      "d1": {
        "lagna_rashi": "Kany",
        "houses": { "1": { "rashi": "Kany", "occupants": ["lagna"] } },
        "graha_positions": {
          "sun": { "rashi": "Mitu", "house": 10, "degree_in_sign": 18.02 }
        }
      },
      "d9": { "lagna_rashi": "Maka" },
      "d10": { "lagna_rashi": "Kany" },
      "d60": { "lagna_rashi": "Dhanu" }
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

Current suite status:

- All fixtures are verified Drik references (`unverified_fixture_count = 0`).
- Verified fixture count floor in CI: `25`.
- `include_unverified=true` returns the same set until new provisional fixtures are added.

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
- `coverage` summary:
  - `timezone_count`, `country_count`
  - `min_birth_year`, `max_birth_year`
  - `dst_observing_timezone_count`
  - `timezones[]`, `countries[]`
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
