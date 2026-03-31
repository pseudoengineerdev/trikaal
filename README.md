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
- Golden reference tests against Reference Panchang for validation
- Progressive, small commits for safe and reviewable iteration

## First Milestone

1. Establish monorepo foundation
2. Scaffold backend service and test harness
3. Implement engine domain model
4. Add golden fixture pipeline for:
   - Date: July 4, 1999
   - Time: 12:22 PM
   - Place: Mumbai, India
5. Block UI development until calculation parity reaches 100%
