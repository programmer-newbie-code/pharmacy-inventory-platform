# Implementation Plan: SIPNAP Regulatory Export

Date: 2026-08-07
Branch: `feat/sipnap-export`

## Tasks

1. **Schema Migration (v7 → v8)**
   - Add `controlledCategory` column to `Products` table

2. **Service & Providers**
   - Create `sipnap_export_service.dart`
   - Register `sipnapExportServiceProvider` in `providers.dart`

3. **UI Screen**
   - Create `sipnap_report_screen.dart`

4. **Tests**
   - Unit tests for SIPNAP export service calculations
   - Widget tests for SIPNAP report screen

5. **Local Pre-flight & CI**
   - `build_runner` build
   - `flutter analyze`
   - `flutter test --coverage`
   - Push branch & open PR
