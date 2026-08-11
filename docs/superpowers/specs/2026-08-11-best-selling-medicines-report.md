# Best-Selling Medicines Report

## Problem

The current `SalesAnalyticsScreen` shows a hard-coded, revenue-ranked top-five list for Today, This Week, and This Month. It aggregates transactions in the widget provider and loads sale/return details one transaction at a time. Staff cannot choose an exact period, rank by units, see gross-versus-return metrics, or export results using the same filters.

## Goal

Give pharmacy staff a localized, return-aware Best-Selling Medicines report for day, week, month, and an exact custom date range, with a predictable ranking and export parity.

## Scope

- Date presets: Today, This Week (Monday through now), This Month, plus an inclusive custom start/end date range.
- Ranking modes: net quantity sold (default) and net revenue.
- Per-medicine fields: rank, medicine name, units sold before returns, returned units, net units, gross revenue, refunded revenue, and net revenue.
- Return attribution comes from the original sale item; quantities and revenue never become negative.
- A repository query/aggregation API performs the range calculation outside the widget tree and avoids per-transaction widget-provider database loops.
- The report has loading, error, and empty states, Indonesian/English ARB strings, accessible controls, and an export using the exact chosen range/ranking.

## Non-goals

- Predictive forecasting, supplier/location/category filtering, cross-device aggregation, tax reconciliation, or changes to historical sale/return records.
- Replacing existing financial, procurement, cash movement, or SIPNAP reports.
- Changing the legal definition of a completed sale or return.

## Acceptance criteria

1. A sale on either boundary date is included; a return on either boundary date is included.
2. Today, week, month, and custom range selections visibly identify the active range.
3. Quantity mode sorts by net units descending; revenue mode sorts by net revenue descending; ties use medicine name ascending for deterministic exports/tests.
4. Returned units and revenue reduce only the matching original medicine; values are clamped at zero.
5. The report lists all ranked medicines, not just five; the UI can present a compact top section without losing access to the full list.
6. Empty ranges explain that no completed sales match the selected period.
7. CSV/XLSX export contains the same rows, range, ranking mode, and column meanings shown on screen, and writes an export audit event.
8. Unit/data tests cover boundaries, multiple sale items, partial/full returns, ranking ties, and no-result data. Widget tests cover presets, custom range, ranking switch, and empty/error states.
9. `flutter analyze`, full tests, CI-equivalent 80% filtered coverage, Windows build, and Android build pass before PR creation.

## Migration and rollback

No schema change is required if the report reads existing sale, sale-item, return, return-item, and product records. The increment is rollback-safe because it does not mutate business data.

## Privacy and permissions

The report exposes only existing pharmacy transaction data. Preserve report permission checks and record exports in the audit trail. Do not include patient/prescription details in the ranking export.
