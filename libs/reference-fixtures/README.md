# Reference Fixtures

Versioned golden fixtures and comparison rules for validation against external standards.

## Current Scope

- JSON schema for reference fixture payloads
- Snapshot comparator with exact and tolerance-based diffing
- Seed canonical fixture for Mumbai (`1999-07-04 12:22`)

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
