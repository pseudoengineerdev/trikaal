# Trikaal

Trikaal is a Vedic astrology platform being built with a mobile-first approach.

## Repository Layout

- `apps/mobile`: Flutter app (primary client)
- `apps/web`: Next.js + TypeScript app (secondary client, later phase)
- `services/api`: Shared backend API and orchestration layer
- `libs/vedic-engine`: Deterministic Vedic calculation engine
- `libs/reference-fixtures`: Golden reference snapshots and comparison rules
- `infra`: Deployment and environment configuration
- `docs`: Architecture, milestones, and decision records

## Development Principles

- Vedic-first calculation model (no western interpretation logic)
- Engine-first delivery: UI work follows engine parity milestones
- Golden reference tests against Drik Panchang for validation
- Progressive, small commits for safe and reviewable iteration

## Accuracy CI Gate

- GitHub workflow: `.github/workflows/accuracy-gate.yml`
- Job name: `Drik Parity Lock`
- Rule: merge should be blocked when parity is not `100.0%` on **verified** Drik fixtures
- Current verified Drik fixture floor: `25` cases
