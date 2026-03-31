# Vedic Engine

Deterministic Vedic astrology calculation engine.

## Current Scope

- Domain contracts for canonical inputs and outputs
- Versioned calculation profile defaults
- Foundation tests for immutable model behavior

## Local Setup

```bash
cd libs/vedic-engine
python3 -m venv .venv
.venv/bin/pip install -e ".[dev]"
```

## Run Tests

```bash
cd libs/vedic-engine
.venv/bin/pytest
```
