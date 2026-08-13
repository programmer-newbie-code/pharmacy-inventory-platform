# Best-Selling Medicines Report Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the widget-level top-five calculation with a localized, return-aware, exportable best-selling medicines report.

**Architecture:** Keep transaction aggregation in `ReportRepository` so feature widgets consume a typed result. Construct a single joined/ordered data set for sale items and a deterministic return-attribution map, then expose it through a Riverpod family keyed by an immutable report filter. Existing report export/audit facilities own file output and audit writes.

**Tech Stack:** Flutter, Drift/SQLite, Riverpod, ARB localization, existing Excel/CSV export services, Flutter tests.

---

## Implementation audit (2026-08-11)

The initial implementation merged in PR #127 supplies a return-aware repository
method, ranking controls, and a custom range picker. It does **not** yet meet
this plan's complete contract: row metrics and typed filter are incomplete,
the screen still has hard-coded strings and widget-level N+1 work, and export
parity/audit feedback are absent. Treat the task checkboxes below as remaining
work unless later evidence explicitly records the corresponding verification.

---

## File map

- Modify: `lib/data/report_repository.dart` — typed filter/result models and efficient aggregation method.
- Modify: `lib/features/reports/sales_analytics_screen.dart` — localized filter controls and typed report rendering; remove widget-level N+1 aggregation.
- Modify: `lib/data/excel_report_service.dart` or create `lib/data/best_selling_medicines_export_service.dart` — export the displayed report rows with metadata.
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb` — all new labels, descriptions, errors, and empty state.
- Modify: `test/data/report_repository_test.dart` — aggregation, boundaries, returns, sorting.
- Modify: `test/features/reports/sales_analytics_screen_test.dart` — filters, mode, empty state, rendering.
- Create or modify: export-service test next to the existing report-export service test.

### Task 1: Specify the typed reporting contract

```dart
enum BestSellingRankMode { netQuantity, netRevenue }

class BestSellingMedicinesFilter {
  const BestSellingMedicinesFilter({
    required this.startDate,
    required this.endDate,
    required this.rankMode,
  });

  final DateTime startDate;
  final DateTime endDate;
  final BestSellingRankMode rankMode;
}

class BestSellingMedicineRow {
  const BestSellingMedicineRow({
    required this.productId,
    required this.productName,
    required this.grossQuantity,
    required this.returnedQuantity,
    required this.netQuantity,
    required this.grossRevenue,
    required this.refundedRevenue,
    required this.netRevenue,
  });
  // Declare the matching int/double fields exactly as named above.
}
```

- [ ] Add immutable `BestSellingMedicinesFilter` with inclusive `startDate`, `endDate`, and `BestSellingRankMode { netQuantity, netRevenue }`.
- [ ] Add immutable `BestSellingMedicineRow` with `productId`, `productName`, `grossQuantity`, `returnedQuantity`, `netQuantity`, `grossRevenue`, `refundedRevenue`, and `netRevenue`.
- [ ] Add a failing repository test fixture containing two products, sales at both date boundaries, a partial return, and a full return.
- [ ] Assert the returned rows contain only the inclusive period and calculate net values without negatives.
- [ ] Commit: `test(reports): define best-selling medicine aggregation contract`.

### Task 2: Implement deterministic repository aggregation

```dart
Future<List<BestSellingMedicineRow>> getBestSellingMedicines(
  BestSellingMedicinesFilter filter,
);
```

Use `createdAt.isBiggerOrEqualValue(filter.startDate)` and an end-of-day
inclusive end value for both sale and return transactions. Build the result from
the selected range only; do not call `getSaleItemsForTransaction` from a widget.

- [ ] In `ReportRepository`, load the selected sale items with their transactions/products using Drift joins, restricted to inclusive `createdAt` bounds.
- [ ] Load return items for returns in the same inclusive range and map each return item to its original sale item/product.
- [ ] Aggregate in maps keyed by product ID, clamp `netQuantity` and `netRevenue` to zero, and sort by the selected mode descending then product name ascending.
- [ ] Run `flutter test test/data/report_repository_test.dart` and confirm Task 1 tests pass.
- [ ] Add cases for tied ranks, returns exceeding a product's selected-period gross amount, and no matching sales.
- [ ] Commit: `feat(reports): aggregate best-selling medicines by period`.

### Task 3: Replace widget-level analytics aggregation

```dart
final bestSellingMedicinesProvider = FutureProvider.autoDispose
    .family<List<BestSellingMedicineRow>, BestSellingMedicinesFilter>(
  (ref, filter) => ref
      .watch(reportRepositoryProvider)
      .getBestSellingMedicines(filter),
);
```

- [ ] Replace `FutureProvider.family<Map<String, dynamic>, DateTimeRange>` values that calculate sale item and return loops in `sales_analytics_screen.dart` with a typed provider that calls the repository contract.
- [ ] Preserve existing financial-summary cards while sourcing the best-selling table from the typed rows.
- [ ] Remove the fixed `.take(5)` data loss. Render an accessible table/list with rank and all seven report metrics.
- [ ] Run `flutter test test/features/reports/sales_analytics_screen_test.dart` and update assertions to use typed localized rows.
- [ ] Commit: `refactor(reports): render typed best-selling medicine rows`.

### Task 4: Add localized range and ranking controls

- [ ] Add ARB messages for report title, Today/Week/Month/Custom, rank-by quantity/revenue, each report column, loading/error/empty copy, and accessible control tooltips in both locales.
- [ ] Regenerate localization with `flutter gen-l10n`.
- [ ] Add a custom-range picker that rejects an end date before the start date and retains the active range after ranking changes.
- [ ] Add widget tests that select every preset, select a custom range, switch ranking modes, and verify the empty state.
- [ ] Run `flutter test test/features/reports/sales_analytics_screen_test.dart`.
- [ ] Commit: `feat(reports): add best-selling medicine filters and ranking`.

### Task 5: Export parity and audit evidence

```dart
Future<File> exportBestSellingMedicines({
  required BestSellingMedicinesFilter filter,
  required List<BestSellingMedicineRow> rows,
  required int userId,
});
```

- [ ] Add an export method that accepts `BestSellingMedicinesFilter` and the exact rows rendered by the report.
- [ ] Include the inclusive date range, ranking mode, and metric columns in deterministic output filename/content.
- [ ] Reuse the existing report-export audit API after a successful write; display localized progress, success, and failure feedback.
- [ ] Add export tests asserting metadata, row order, row metrics, and audit invocation.
- [ ] Commit: `feat(reports): export best-selling medicine results`.

### Task 6: Local and PR verification

- [ ] Run `dart run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n`; restore unrelated generated Windows plugin files before committing.
- [ ] Run `flutter analyze` with no diagnostics.
- [ ] Run `flutter test --coverage`, then calculate the CI-equivalent filtered metric excluding `**/*.g.dart`, `lib/l10n/*`, and `lib/data/database.dart`; expect at least 80%.
- [ ] Run Windows and Android builds when the local toolchain is available.
- [ ] Create a signed branch commit and PR with problem, scope, screenshots, tests, migration/rollback, risks, and export/audit evidence. Monitor all CI gates, fix forward until green, squash-merge, and verify green main CI.
