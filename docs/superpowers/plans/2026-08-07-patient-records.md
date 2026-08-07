# Implementation Plan: Patient Records & E-Prescription

Date: 2026-08-07
Branch: `feat/patient-records`

## Tasks

1. **Schema Migration (v5 → v6)**
   - Add `Patients` and `Prescriptions` tables
   - Add `patientId` foreign key to `SaleTransactions`

2. **Repositories & Providers**
   - Create `patient_repository.dart`
   - Create `prescription_repository.dart`
   - Register providers in `providers.dart`

3. **UI Screens**
   - Create `patient_list_screen.dart`
   - Create `patient_form_screen.dart`
   - Create `patient_detail_screen.dart`

4. **Tests**
   - Unit tests for patient & prescription repositories
   - Widget tests for patient directory & detail screens

5. **Local Pre-flight & CI**
   - `build_runner` build
   - `flutter analyze`
   - `flutter test --coverage`
   - Push branch & open PR
