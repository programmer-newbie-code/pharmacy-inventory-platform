# Implementation plan: procurement and cash-movement export/audit parity

**Spec:** `2026-08-11-procurement-cash-export-audit.md`

## Current evidence

- `ProcurementReportScreen` renders a selected-range `ProcurementSummary` but
  has no export/action/audit path.
- `CashMovementReportScreen` renders selected-range `CashMovement` rows but
  has no export/action/audit path.
- `ReportRepository.exportBestSellingMedicines` and the corresponding Excel
  service from PR #130 provide the established successful-save-then-audit
  pattern to mirror.

## Tasks

1. Add immutable export input/value types as needed and Excel generators/save
   methods for procurement summary/supplier rows and cash movement rows.
   Preserve input order and create deterministic filenames.
2. Add `ReportRepository` export methods that receive the screen's existing
   data, call the Excel save method, then write an audit event only after save
   success. Include user, period, and row-count details.
3. Add all English and Indonesian ARB strings, regenerate localization, and
   add accessible export actions with busy, disabled, success, and failure
   states to both reports.
4. Replace report-local hard-coded operational UI strings in the affected
   screens with ARB strings while touching those surfaces.
5. Add focused service/repository/widget tests for output content/order,
   filename shape, successful audit logging, empty state, disabled state, and
   busy/success feedback.
6. Run formatter, l10n/code generation where needed, analyzer, focused/full
   tests, CI-equivalent coverage, and Windows/Android builds. Push a signed
   PR with the evidence, monitor every required check, fix-forward, squash
   merge only when green, and verify green main.

## Test matrix

| Area | Evidence |
| --- | --- |
| Excel | headers, metadata, supplied row order, non-empty output, filenames |
| Repository | save succeeds before audit; audit action/user/details are correct |
| Procurement UI | export disabled without supplier rows; busy/success with rows |
| Cash UI | export disabled without movements; busy/success with rows |
| Regression | existing report rendering and range providers remain functional |

## No migration/rollback work

No tables or stored records change. Revert is code-only; successfully saved
files and audit events are intentionally retained as historical evidence.
