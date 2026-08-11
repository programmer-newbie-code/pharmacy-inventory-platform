# Best-Selling Medicines Export & Audit

> Retroactive spec, written after PR #130 merged. Documents the increment for
> future reference and to close Task 5 of
> `docs/superpowers/plans/2026-08-11-best-selling-medicines-report.md`.

## Problem

The Best-Selling Medicines report (PR #127–#129) had no export capability,
unlike every other report in the app (sales, procurement, cash movement,
SIPNAP). Separately, `ReportRepository.logExport` existed but had zero
production callers — `reportRepositoryProvider` never injected an
`AuditLogger`, so no report export (old or new) was ever actually recorded
in the audit trail in production, despite the method existing and being
unit-tested in isolation.

## Goal

Let pharmacy staff export the Best-Selling Medicines report they're viewing
to Excel, with the exported rows exactly matching what's on screen, and
record every export in the audit trail.

## Scope

- An Excel (.xlsx) export of the currently displayed Best-Selling Medicines
  report: title, period, rank mode, and all seven row metrics (rank, product
  name, gross/returned/net quantity, gross/refunded/net revenue).
- Export uses the exact rows already fetched for the screen — no re-query,
  no re-sort — so the file always matches what the user saw.
- An accessible export button on `SalesAnalyticsScreen`, disabled when there
  is nothing to export, with a busy state while writing the file and
  localized (en/id) success/failure feedback.
- Every successful export writes one audit-log row via the existing
  `ReportRepository.logExport` method.
- Fixing the pre-existing gap: `reportRepositoryProvider` now injects
  `AuditLogger` and `ExcelReportService` so `logExport` (used by this and any
  future report export) actually persists in production, not just in tests
  that construct `ReportRepository` directly.

## Non-goals

- CSV export for this report (Excel only, matching the other analytics
  report's format).
- Export deletion/retention policy.
- Changing the best-selling aggregation logic itself (already shipped).

## Acceptance criteria

1. Exported file contains the same rows, in the same order, as currently
   rendered — never a fresh independent query.
2. Filename is deterministic and descriptive: encodes the period, rank mode,
   and a generation timestamp.
3. Sheet includes a title row, a metadata row (period + rank mode label),
   a header row, and one row per medicine.
4. An empty best-selling list still produces a valid file (header only); the
   UI disables the export action in that case with an explanatory tooltip.
5. Every successful export calls `logExport` with the correct `userId`,
   `exportType`, and period/rank-mode/row-count details.
6. Export button is reachable/labeled for screen readers (tooltip explains
   idle/exporting/disabled states); minimum tap target unchanged from
   `OutlinedButton` default.
7. `flutter analyze`, full test suite, and CI-equivalent 80% filtered
   coverage pass before merge.

## Migration and rollback

No schema change. Pure repository/service/UI addition — rollback is a normal
PR revert.

## Notes for future increments (lessons from this one)

- The `excel` package's `Sheet.appendRow([])` with an empty list does **not**
  advance the row index — verify row-index assumptions against
  `Excel.decodeBytes(bytes)` output in a real test before writing row-index
  assertions, don't assume from the sales-report sheet's structure.
- `DateTime(...)` constructor calls are not `const` — a `const Filter(...)`
  wrapping one will fail `flutter analyze`, not just at runtime.
- No local Flutter/Dart SDK was available in the implementation environment;
  verification relied entirely on CI. Two analyzer/test failures were only
  caught after pushing. Future increments should budget for at least one
  fix-forward CI cycle when no local toolchain is available, or set up local
  execution (e.g. a working Flutter Docker image with enough free disk) before
  starting implementation.
