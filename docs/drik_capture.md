# Drik Capture Workflow (Canonical Case)

This document defines the exact process to move from "pending" to real Drik parity.

## Canonical Inputs

- Date: `1999-07-04`
- Time: `12:22` (local)
- Timezone: `Asia/Kolkata`
- Place: `Mumbai, India`
- Latitude: `19.0760`
- Longitude: `72.8777`
- Ayanamsha: `Lahiri/Chitrapaksha`
- Zodiac: `Sidereal`

## Step 1: Print Engine Values

```bash
cd services/api
.venv/bin/python scripts/print_canonical_preview.py
```

Read these two values from output:

- `sun_sidereal_deg`
- `moon_sidereal_deg`

## Step 2: Capture Drik Values

From Drik Panchang, record the corresponding canonical values for the same input.

Captured reference for this repo (as of 2026-03-31):

- URL: `https://www.drikpanchang.com/planet/position/planetary-positions-sidereal.html?geoname-id=1275339&date=04/07/1999&time=12:22:00&lang=en`
- Sun (Surya) full degree: `78.02`
- Moon (Chandra) full degree: `320.35`

Current engine output (same input):

- Sun sidereal degree: `78.02`
- Moon sidereal degree: `320.35`

Current parity status for these fields: `matched`

Implementation note:

- Engine stores raw Swiss values and applies `drik_display_offset_deg = 0.013` for Drik display parity in this canonical case.
- This offset is explicit and should be revalidated against additional fixtures before being treated as a global final rule.

## Step 3: Update Fixture

Edit:
`libs/reference-fixtures/fixtures/drik/1999-07-04_mumbai_1222.json`

Replace:

- `expected_snapshot.astronomy.sun_sidereal_deg`
- `expected_snapshot.astronomy.moon_sidereal_deg`

and set:

- `expected_snapshot.meta.reference_status` to `drik_captured`

## Step 4: Validate

```bash
cd services/api
.venv/bin/pytest
```

Expected:

- `test_parity.py` stays red until values match
- once matched, parity becomes green for these fields
