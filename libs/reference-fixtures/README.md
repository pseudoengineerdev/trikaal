# Reference Fixtures

Versioned golden fixtures and comparison rules for validation against external standards.

## Current Scope

- JSON schema for reference fixture payloads
- Snapshot comparator with exact and tolerance-based diffing
- Multi-case Drik fixture suite (`fixtures/drik/*.json`)

Current suite includes:

- `1999-07-04 12:22` Mumbai (canonical baseline)
- `1973-04-24 13:00` Mumbai (Sachin reference)
- `2018-01-04 17:44` Chennai (archived export reference)

## Local Setup

```bash
cd libs/reference-fixtures
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
```

## Run Tests

```bash
cd libs/reference-fixtures
.venv/bin/pytest
```
