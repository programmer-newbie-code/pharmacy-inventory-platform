# Pharmacy Inventory Platform

Offline-first inventory and point-of-sale app for small pharmacies. Single Flutter
codebase, installable on Windows (desktop `.exe`) and Android.

See [`docs/superpowers/specs/2026-07-08-pharmacy-inventory-platform-design.md`](docs/superpowers/specs/2026-07-08-pharmacy-inventory-platform-design.md)
for the full product design.

## Stack

- Flutter (stable channel) — one codebase, Windows + Android
- `drift` — local SQLite database
- `flutter_riverpod` — state management
- ARB-based i18n — `id` (default) and `en`

## Getting started

```bash
flutter create --platforms=windows,android --org com.programmernewbiecode .
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run -d windows   # or: flutter run -d <android-device-id>
```

`android/` and `windows/` are not committed — the first command above generates them
locally. This keeps the repo free of generated platform boilerplate until a native
customization requires hand-editing it (see `.gitignore`).

## Architecture

```
lib/
  domain/     # business logic — pure Dart, no Flutter/drift dependency
  data/       # drift database (schema + generated code)
  features/   # one folder per screen/feature
  core/       # shared utilities (empty until a second feature needs one)
```

## Contributing

All changes go through a PR. CI must be green (`flutter analyze`, tests at ≥80% line
coverage, Windows build, Android build) before merge — branch protection enforces
this on `main`.
