# Mobile Architecture (Flutter)

This document defines the current structure for mobile so new features stay modular.

## Core Principle

Feature-first organization with clear separation:

- `data`: API clients and transport models
- `presentation`: UI widgets and screen orchestration
- `presentation/state`: page-level controller/state logic

## Design System (Phase 1)

Path map:

- `lib/app/theme/trikaal_theme.dart`
  - Brand palette, typography, component theming tokens
- `lib/app/widgets/astro_page_background.dart`
  - Shared gradient backdrop and atmospheric decorative layer

Rule:

- Pages should use shared theme tokens and background shell instead of one-off colors/styles.

## Current Charts Flow

Path map:

- `lib/features/charts/data/chart_api_client.dart`
  - Calls backend endpoints:
    - `POST /v1/charts/compute`
    - `GET /v1/places/search`
- `lib/features/charts/data/models/*`
  - Request/response and place-search model contracts
- `lib/features/charts/presentation/state/birth_chart_controller.dart`
  - Submit flow
  - Debounced place search
  - Loading/error/result state
- `lib/features/charts/presentation/birth_input_page.dart`
  - Screen composition and input handling
- `lib/features/charts/presentation/widgets/*`
  - Reusable UI blocks for result and state rendering
  - Includes Detailed Kundli sections (graha table, house placements, dignity)
  - Includes tap-to-expand graha deep-view drawer from the graha table
  - Includes explainable Interpretation cards (what + why + impact)
  - Includes interpretation card detail drawer with dasha-tied action guidance
  - Includes Daily Transit Brief cards (focus, summary, do/watch actions)

## Saved Profiles Flow

Path map:

- `lib/app/models/saved_birth_profile.dart`
  - Saved profile contract for DOB/time/place and optional resolved place payload
- `lib/app/data/saved_profiles_repository.dart`
  - Local persistence adapter (`SharedPreferences`)
- `lib/app/state/birth_input_state.dart`
  - Profile lifecycle: load/create/apply/rename/default/update/delete
- `lib/features/charts/presentation/birth_input_page.dart`
  - Saved Profiles UI section and profile actions

## State Ownership Rule

- Controller owns async/business state (`loading`, `error`, `result`, `suggestions`)
- Screen owns view-only concerns (text controllers, date/time pickers, form validation)

This keeps API/state code testable and reduces widget complexity.

## Test Strategy

Current:

- Widget smoke test: `test/widget_test.dart`
- Controller unit tests:
  - `test/features/charts/presentation/state/birth_chart_controller_test.dart`

Recommended for each new feature module:

1. Unit tests for controller/state
2. One widget smoke test for primary screen
3. Contract checks for model parsing if payload shape grows

## How to Add New Modules

For upcoming domains like `dasha`, `kundli`, `reports`:

1. Create `lib/features/<module>/data/` for API + models.
2. Create `lib/features/<module>/presentation/state/` for controller.
3. Create `lib/features/<module>/presentation/widgets/` for reusable UI pieces.
4. Keep screens thin; push async logic to controller.
5. Add matching tests under `test/features/<module>/...`.

## Naming Conventions

- API clients: `<feature>_api_client.dart`
- Controller: `<screen>_controller.dart`
- State widgets: `<feature>_state_widgets.dart`
- Result/detail widgets: `<feature>_result_card.dart`

## Networking Configuration

- Base URL is configured in `lib/config/app_config.dart`
- Override per run:

```bash
flutter run --dart-define=TRIKAAL_API_BASE_URL=http://10.0.2.2:8000
```

Android emulator should use `10.0.2.2` for localhost API access.
