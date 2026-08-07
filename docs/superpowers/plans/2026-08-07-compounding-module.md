# Implementation Plan: Compounding / Obat Racikan Module

Date: 2026-08-07
Branch: `feat/compounding-module`

## Tasks

1. **Schema Migration (v6 → v7)**
   - Add `CompoundingFormulas`, `CompoundingIngredients`, `CompoundingTransactions`, `CompoundingTransactionItems` tables

2. **Repositories & Providers**
   - Create `compounding_repository.dart`
   - Register provider in `providers.dart`

3. **UI Screens**
   - Create `formula_list_screen.dart`
   - Create `formula_editor_screen.dart`

4. **Tests**
   - Unit tests for compounding repository & cost math
   - Widget tests for formula list & editor screens

5. **Local Pre-flight & CI**
   - `build_runner` build
   - `flutter analyze`
   - `flutter test --coverage`
   - Push branch & open PR
