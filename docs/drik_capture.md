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
