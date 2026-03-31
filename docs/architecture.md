# Architecture (v1)

## Product Direction

Trikaal is a Vedic astrology system where calculation accuracy is the primary deliverable.

## Core Rule

No UI implementation proceeds until the calculation engine passes the golden reference suite with 100% match for the initial canonical test case.

## High-Level Components

1. Shared backend API
2. Vedic calculation engine
3. Reference fixture and parity test harness
4. Mobile app (Flutter)
5. Web app (Next.js, later phase)

## Shared Backend Contract

Both clients consume the same API and never perform astrology calculations locally.

## Canonical Test Case

- Date: 1999-07-04
- Time: 12:22 (local time)
- Timezone: Asia/Kolkata
- Place: Mumbai, India

## Validation Strategy

- Deterministic domain model and pure calculation functions
- Golden fixtures sourced from Drik Panchang
- Strict snapshot comparison for user-visible output fields
