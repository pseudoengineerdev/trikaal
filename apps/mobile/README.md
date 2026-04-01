# Mobile App (Flutter)

Primary client application for Trikaal.

## Status

Engine integration scaffold added (manual setup).

This folder now includes:

- Flutter app skeleton (`lib/main.dart`)
- API config (`lib/config/app_config.dart`)
- Chart API client (`lib/features/charts/data/chart_api_client.dart`)
- Saved Profiles (`lib/app/state/birth_input_state.dart` + local persistence)
- Request/response models for:
  - `POST /v1/charts/compute`
  - `GET /v1/places/search`

Architecture guide:

- `apps/mobile/docs/architecture.md`

## Local Run (after Flutter install)

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Backend Base URL

Set the API URL using Dart define:

```bash
flutter run --dart-define=TRIKAAL_API_BASE_URL=http://127.0.0.1:8000
```
