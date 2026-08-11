# Best-Selling Medicines Export & Audit Implementation Plan

> Retroactive plan, written after PR #130 merged. Kept as a reference for
> future report-export increments (e.g. procurement, cash movement export
> parity) and to record what was actually built/verified.

**Goal:** Add Excel export + audit logging for the Best-Selling Medicines
report, reusing the existing report-export patterns in the codebase.

**Architecture:** `ExcelReportService` gains a
`generateBestSellingMedicinesReport`/`exportAndSaveBestSellingMedicinesReport`
pair mirroring the existing sales-report methods. `ReportRepository` gains
`exportBestSellingMedicines`, which calls the Excel service with the exact
rows already rendered on screen, then calls the existing (previously
production-unused) `logExport`. `reportRepositoryProvider` is wired to inject
`AuditLogger` + `ExcelReportService` so the audit call actually persists.

**Tech Stack:** Flutter, `excel` package v4, Riverpod, ARB localization,
`flutter_test` with `Directory.systemTemp` overrides for file-writing tests
(no `path_provider` mocking needed).

---

## File map

- Modify: `lib/data/excel_report_service.dart` — new generate/export methods.
- Modify: `lib/data/report_repository.dart` — `exportBestSellingMedicines`,
  constructor now accepts `ExcelReportService`.
- Modify: `lib/core/providers.dart` — `reportRepositoryProvider` injects
  `AuditLogger` and `ExcelReportService`.
- Modify: `lib/features/reports/sales_analytics_screen.dart` — export button,
  `_isExporting` state, `_exportBestSelling` handler.
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb` — export strings.
- Modify: `test/data/excel_report_service_test.dart`,
  `test/data/report_repository_test.dart`,
  `test/features/reports/sales_analytics_screen_test.dart`.

## Task 1: Excel generation (`generateBestSellingMedicinesReport`)

**Step 1: Write the failing test.**

In `test/data/excel_report_service_test.dart`, add a `group` with a test
that calls `service.generateBestSellingMedicinesReport(filter:, rows:)` with
two rows and asserts, via `Excel.decodeBytes(bytes)`:
- Sheet name `'Best-Selling Medicines'`.
- Metadata row (index 1) contains the period dates and rank-mode label.
- Header row contains exactly the 8 expected column names.
- Data rows are in the same order as the input `rows` (no re-sort).

**Verify against the real API first:** before asserting row *indices*,
write a throwaway script or test that dumps `sheet.rows` for a minimal
2-title-row + append pattern, because `Sheet.appendRow([])` with an empty
list does **not** advance the row index (confirmed the hard way — see spec
notes). Expect: title=0, metadata=1, headers=2, data=3+.

**Step 2:** Run `flutter test test/data/excel_report_service_test.dart` —
expect FAIL (method doesn't exist yet).

**Step 3: Implement.** Add the method to `ExcelReportService`, following the
exact pattern of `generateSalesReport` (rename `Sheet1`, `appendRow` per
line, `NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ')` for currency
cells, `IntCellValue`/`TextCellValue` per column type). Do **not** call
`sheet.appendRow([])` as a spacer — it's a no-op for row indexing.

**Step 4:** Run tests again — expect PASS.

**Step 5:** Also add a header-only-sheet test for `rows: []`, asserting
`sheet.maxRows == 3` (title + metadata + header, no data rows).

## Task 2: File-writing (`exportAndSaveBestSellingMedicinesReport`)

**Step 1:** Add a test using `Directory.systemTemp.createTemp(...)` +
`baseDirectoryOverride` param (same pattern as
`ReceiptStorageService`/`exportAndSaveReport`) — assert the file exists,
filename contains the period dates + rank-mode slug + `.xlsx`, and bytes are
non-empty.

**Step 2–4:** Implement with `baseDirectoryOverride ??
await getApplicationDocumentsDirectory()`; run test to green.

## Task 3: Repository export + audit (`ReportRepository.exportBestSellingMedicines`)

**Step 1:** Add constructor param `ExcelReportService? excelReportService`
(default to `ExcelReportService()` if null, matching the existing
`AuditLogger?` optional-injection pattern).

**Step 2:** Add
`exportBestSellingMedicines({filter, rows, userId, baseDirectoryOverride})`:
delegates to the Excel service, then calls `logExport(userId:, exportType:
'best_selling_medicines', details: <period + rankMode + row count>)`.

**Step 3:** Test: construct `ReportRepository(db, auditLogger:
AuditLogger(db), excelReportService: ExcelReportService())`, call the method
with a temp `baseDirectoryOverride`, assert the file exists and exactly one
audit-log row was written with `action == 'export_best_selling_medicines'`.

## Task 4: Wire the DI gap

**Step 1:** In `lib/core/providers.dart`, change
`reportRepositoryProvider` to inject `auditLogger:
ref.watch(auditLoggerProvider)` and `excelReportService:
ref.watch(excelReportServiceProvider)`. **Careful:** if reordering provider
declarations, diff the full file afterward — a naive block-replace can
silently delete unrelated providers declared in between (this happened once
during this increment and was caught by re-reading the diff before commit).

## Task 5: UI — export button

**Step 1:** Add `bool _isExporting` state and `_exportBestSelling(rows)`
handler to `_SalesAnalyticsScreenState`, following
`ReportsScreen._exportExcel`'s try/finally + `ScaffoldMessenger` SnackBar
pattern exactly (green `AppTheme.successColor` / red `AppTheme.dangerColor`).

**Step 2:** Add an `OutlinedButton.icon` next to the "Best-Selling
Medicines" heading: `key: const Key('exportBestSellingBtn')` for
testability, wrapped in `Tooltip` with a message that changes for
idle/exporting/disabled-empty states, `onPressed: null` when
`topProducts.isEmpty || _isExporting`.

**Step 3:** Add ARB keys (en + id, verified key-parity with a small Python
JSON diff check) for button label, tooltip states, saved/failed feedback.

## Task 6: Widget tests

**Step 1:** Test with seeded sales data — export button `onPressed` is
non-null, tapping it flips to a busy `CircularProgressIndicator`.

**Step 2:** Test with an empty database — export button `onPressed` is
`null`.

(Real file-write success is covered at the repository level in Task 3 —
widget tests only assert UI state transitions, matching the precedent in
`reports_screen_test.dart` which doesn't mock `path_provider` either.)

## Task 7: Local and PR verification

**Step 1:** No local Flutter SDK was available in this environment.
Attempted a `ghcr.io/cirruslabs/flutter:stable` Docker pull as a
verification fallback — stalled repeatedly on a large layer with ~13GB free
disk. **Lesson: check available disk space before attempting this, or
provision a machine with a working Flutter toolchain before starting.**

**Step 2:** Pushed and relied on CI (`analyze-and-test`, `build-windows`,
`build-android`, `secret-scan`, `verify-signatures`) as the actual gate.

**What CI caught (2 fix-forward commits):**
1. `const BestSellingMedicinesFilter(startDate: DateTime(...))` —
   `DateTime()` isn't `const`; changed all three test call-sites to
   non-const `final filter = ...`.
2. Row-index assumptions — `sheet.appendRow([])` doesn't advance the index;
   removed the no-op spacer call and corrected test row indices.

**Step 3:** Once `analyze-and-test`, `build-windows`, `build-android`,
`secret-scan`, and `verify-signatures` were all green, squash-merged and
confirmed main CI green post-merge.
