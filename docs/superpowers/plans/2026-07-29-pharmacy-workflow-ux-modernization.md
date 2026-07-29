# Pharmacy Workflow UX Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make daily cashier, inventory, admin, and audit work faster, clearer, responsive, localized, and accessible.

**Architecture:** Add a small shared presentation layer for responsive navigation and operational status, then reshape existing screens without changing domain rules. Use role permissions to prioritize workflows. File import becomes a staged parse/preview/commit process.

**Tech Stack:** Flutter Material 3, Riverpod, ARB localization, existing drift repositories, `file_picker`.

---

## File map

- Modify `lib/core/app_theme.dart`: disciplined pharmacy design tokens.
- Create `lib/core/responsive_layout.dart`: phone/desktop breakpoints.
- Create `lib/features/home/operational_status_strip.dart`.
- Modify `lib/features/home/home_screen.dart`: role-first dashboard/navigation.
- Modify `lib/features/inventory/product_list_screen.dart`: live search and import entry.
- Create `lib/features/inventory/csv_import_dialog.dart`: file, preview, result stages.
- Modify `lib/data/csv_import_service.dart`: parse/validate separately from commit.
- Modify all feature screens only to remove hardcoded text and align states/actions.
- Modify ARB files and focused widget tests.

### Task 1: Establish design tokens and responsive shell

**Files:**
- Modify: `lib/core/app_theme.dart`
- Create: `lib/core/responsive_layout.dart`
- Create: `test/core/responsive_layout_test.dart`

- [ ] **Step 1: Add breakpoint tests**

```dart
expect(AppBreakpoint.fromWidth(479), AppBreakpoint.phone);
expect(AppBreakpoint.fromWidth(800), AppBreakpoint.tablet);
expect(AppBreakpoint.fromWidth(1200), AppBreakpoint.desktop);
```

- [ ] **Step 2: Implement breakpoints**

Use phone `< 600`, tablet `600–1023`, desktop `>= 1024`. Expose only helpers
needed by two or more screens.

- [ ] **Step 3: Refine theme**

Keep deep teal brand. Limit functional palette to:

```dart
primary: Color(0xFF006D67)
surface: Color(0xFFFFFFFF)
background: Color(0xFFF4F7F6)
success: Color(0xFF287A47)
warning: Color(0xFFA65D00)
danger: Color(0xFFB3261E)
info: Color(0xFF245EA8)
```

Retain medicine-category colors because they encode Indonesian regulatory
meaning. Add visible focus, 48dp controls, consistent 12/16px radii, and
tabular figures for money/stock where supported.

- [ ] **Step 4: Verify**

Run: `flutter test test/core/responsive_layout_test.dart && flutter analyze`

- [ ] **Step 5: Commit**

```bash
git add lib/core/app_theme.dart lib/core/responsive_layout.dart test/core/responsive_layout_test.dart
git commit -m "refactor(ui): establish responsive pharmacy design system"
```

### Task 2: Build role-first app navigation

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Create: `lib/features/home/operational_status_strip.dart`
- Modify: `test/features/home/home_screen_test.dart`
- Modify: ARB files

- [ ] **Step 1: Write failing responsive tests**

At 390px, assert bottom navigation and no navigation rail. At 1280px, assert
navigation rail and no bottom navigation. For cashier role, assert “Mulai
Penjualan” is primary. For inventory role, assert “Terima Stok” is primary.

- [ ] **Step 2: Implement operational status model**

```dart
class OperationalStatus {
  const OperationalStatus({
    required this.hasOpenShift,
    required this.lastBackupAt,
    required this.lowStockCount,
    required this.expiringCount,
  });
  final bool hasOpenShift;
  final DateTime? lastBackupAt;
  final int lowStockCount;
  final int expiringCount;
}
```

- [ ] **Step 3: Reshape dashboard**

Order content: role-specific primary action, status strip, attention list,
secondary destinations. Hide unauthorized destinations from routine navigation;
permission checks still remain at screen/repository boundaries.

- [ ] **Step 4: Add actionable errors**

Dashboard stats failure displays a retry control instead of disappearing through
`SizedBox.shrink()`.

- [ ] **Step 5: Verify and commit**

Run: `flutter test test/features/home/home_screen_test.dart`

```bash
git add lib/features/home lib/l10n test/features/home/home_screen_test.dart
git commit -m "feat(home): prioritize role-specific pharmacy workflows"
```

### Task 3: Replace paste-based CSV import with staged file import

**Files:**
- Modify: `lib/data/csv_import_service.dart`
- Create: `lib/features/inventory/csv_import_dialog.dart`
- Modify: `lib/features/inventory/product_list_screen.dart`
- Modify: `test/data/csv_import_service_test.dart`
- Create: `test/features/inventory/csv_import_dialog_test.dart`
- Modify: ARB files

- [ ] **Step 1: Define preview result**

```dart
class CsvImportPreview {
  const CsvImportPreview({
    required this.validRows,
    required this.errors,
    required this.duplicateBarcodes,
  });
  final List<ProductImportRow> validRows;
  final List<CsvRowError> errors;
  final Set<String> duplicateBarcodes;
}
```

Parsing performs no writes. Commit accepts only rows confirmed by user.

- [ ] **Step 2: Test validation**

Cover missing headers, malformed prices, missing barcode/name, duplicate rows in
file, duplicates already in DB, mixed valid/invalid rows, and UTF-8 Indonesian
names.

- [ ] **Step 3: Build staged dialog**

Stages:

1. Choose `.csv`.
2. Preview counts and first 20 rows.
3. Choose duplicate policy: skip existing only.
4. Import.
5. Show imported/skipped/failed counts and error details.

Do not prefill sample products. Provide a separate “Download format example”
action if a platform-safe export utility already exists; otherwise show expected
column names in help copy.

- [ ] **Step 4: Keep Indonesian catalog safe**

Add explanatory copy: bundled catalog helps fill medicine name/category/unit but
does not create inventory. Do not synthesize barcode, cost, supplier, batch,
stock, or expiry.

- [ ] **Step 5: Verify and commit**

Run:

```bash
flutter test test/data/csv_import_service_test.dart
flutter test test/features/inventory/csv_import_dialog_test.dart
```

```bash
git add lib/data/csv_import_service.dart lib/features/inventory lib/l10n test/data/csv_import_service_test.dart test/features/inventory
git commit -m "feat(inventory): preview and validate CSV imports"
```

### Task 4: Improve inventory discovery and attention states

**Files:**
- Modify: `lib/features/inventory/product_list_screen.dart`
- Modify: `test/features/inventory/product_list_screen_test.dart`
- Modify: ARB files

- [ ] **Step 1: Add failing interaction tests**

Test 300ms debounced live search, clear action, no-results message containing the
query, low-stock filter, and receive-stock primary action.

- [ ] **Step 2: Remove N+1 stock loading**

Add one repository query returning products with aggregated stock instead of one
`getTotalStockForProduct` call per product. Cover it in
`test/data/product_repository_test.dart`.

- [ ] **Step 3: Implement inventory states**

Show product name, barcode, category marker, stock number, unit, and one clear
action. Empty catalog offers “Tambah produk”; no-result state offers “Hapus
pencarian”; loading preserves layout with progress semantics.

- [ ] **Step 4: Verify and commit**

Run:

```bash
flutter test test/data/product_repository_test.dart
flutter test test/features/inventory/product_list_screen_test.dart
```

Commit: `feat(inventory): streamline product discovery and stock actions`.

### Task 5: Localize and standardize every feature state

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_id.arb`
- Modify: files under `lib/features/`
- Modify: relevant widget tests

- [ ] **Step 1: Inventory hardcoded strings**

Run:

```bash
rg -n "Text\(['\"]|labelText: ['\"]|hintText: ['\"]|tooltip: ['\"]" lib/features
```

Classify each result as localized UI copy or non-user-visible constant.

- [ ] **Step 2: Move UI copy into ARB**

Use consistent verbs: Tambah, Simpan, Pulihkan, Coba lagi, Batalkan. Raw
exceptions remain in logs/tests only.

- [ ] **Step 3: Standardize states**

Every async screen implements loading, empty, data, recoverable failure, and
success feedback. Destructive operations state the consequence before confirm.

- [ ] **Step 4: Verify**

Run:

```bash
flutter gen-l10n
flutter test
flutter analyze
```

Expected: no hardcoded operational copy except approved brand/protocol constants.

- [ ] **Step 5: Commit**

Commit: `localize(ui): standardize pharmacy workflow feedback`.

### Task 6: Accessibility and platform interaction pass

**Files:**
- Modify: shared theme and affected feature widgets
- Create: `test/features/accessibility_workflow_test.dart`

- [ ] **Step 1: Add semantic tests**

Assert primary actions have text labels, disabled actions explain why, form
errors associate with fields, and critical statuses include text—not color only.

- [ ] **Step 2: Add Windows keyboard tests**

Verify Tab reaches search, primary action, list action, and app navigation in
logical order; Enter/Space activates focused controls; Escape closes dialogs.

- [ ] **Step 3: Add phone overflow tests**

Render primary screens at 360×640 and assert no overflow exceptions. Render
desktop at 1366×768 and verify workspace navigation.

- [ ] **Step 4: Verify and commit**

Run: `flutter test test/features/accessibility_workflow_test.dart`

Commit: `test(ui): enforce responsive and accessible workflows`.

### Task 7: Full verification and PR

- [ ] Run code generation, analyze, coverage tests, Windows build, Android build.
- [ ] Manually exercise cashier, inventory, admin, and audit roles at phone and
  desktop sizes.
- [ ] Push `feat/pharmacy-workflow-ux`.
- [ ] Create PR titled `feat(ui): modernize role-based pharmacy workflows`.
- [ ] Watch all checks, fix forward, squash merge only when green.
- [ ] Verify main build before tagging the next minor release.
