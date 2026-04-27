# Pancha Pakshi Source Of Truth

This document defines what is canonical in the Pancha Pakshi stack and what is presentation-only.

## Canonical Computed Fields (Engine Truth)

These are computed by `libs/vedic-engine/src/vedic_engine/pancha_pakshi.py` and must remain deterministic for the same input:

- Birth identity:
  - `birth.nakshatra_number`
  - `birth.nakshatra_name`
  - `birth.paksha`
  - `birth.pakshi`
- Runtime context:
  - `runtime.reference_place_label`
  - `runtime.reference_timezone`
  - `runtime.weekday`
  - `runtime.paksha`
  - `runtime.phase` (`day` or `night`)
  - `runtime.phase_window_start_local_iso`
  - `runtime.phase_window_end_local_iso`
  - `runtime.next_transition_local_iso`
  - `runtime.seconds_remaining_in_active_sub_activity`
- Active window:
  - `active.major_index`
  - `active.main_bird`
  - `active.main_activity`
  - `active.sub_activity.*`
- Timeline:
  - exactly 10 major windows (current phase + next phase)
  - each major window has exactly 5 sub windows
  - no timeline gaps or overlaps
  - per-major sub-window durations follow paksha+phase duration units

## Canonical Rule Inputs

The following rule sources are authoritative for current implementation:

- Star-to-bird mapping: `STAR_BIRD_BY_PAKSHA`
- Relation mapping: `RELATION_SEQUENCE_BY_PAKSHA`
- Duration units: `DURATION_UNITS_BY_PAKSHA_PHASE`
- CSV sequencing: `pyjhora` `pancha_pakshi_db.csv` ordering for major/sub activities

## Presentation-Only Fields (Non-Canonical)

These are UI render decisions and must never be fed back into engine validation:

- Emoji decorations for birds, activities, paksha, or day/night
- Text formatting:
  - AM/PM formatting
  - readable date formatting (`Apr 10, 2026`)
  - “Xh Ym” duration labels
  - labels like “Today + Tonight Timeline”
- Visual indicators:
  - plus signs (`++++`) for effect strength
  - color coding for effect badges
  - animated hourglass
- Layout behavior:
  - card expansion defaults
  - section ordering
  - tab labels

## Accuracy Lock Tests

Accuracy lock is enforced using:

- Shared fixture suite:
  - `libs/reference-fixtures/fixtures/pancha_pakshi/realtime_lock_cases_v1.json`
- Engine lock + invariants:
  - `libs/vedic-engine/tests/test_pancha_pakshi_accuracy_lock.py`
- API lock + invariants:
  - `services/api/tests/test_pancha_pakshi_accuracy_lock.py`

Fixture suite intentionally includes:

- Shukla and Krishna paksha cases
- Day and night phase cases
- Multi-city runtime contexts
- DST edge cases (spring-forward and fall-back)

When changing engine rule logic, update fixture data in the same PR and explain the reason in the PR description.
