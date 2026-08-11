# Procurement and cash-movement export/audit parity

**Status:** Proposed implementation
**Date:** 2026-08-11

## Problem and current-state evidence

The procurement report obtains a `ProcurementSummary` for the selected date
range and renders its metrics and supplier spend breakdown. The cash-movement
report obtains the selected range's `CashMovement` rows and renders its metrics
and history. Neither screen offers an export action, writes an export audit
record, or gives export progress/result feedback. The procurement screen also
has English hard-coded operational strings; the cash report has hard-coded
Indonesian empty/error strings. This conflicts with the ARB-only UI rule.

The current `ReportRepository` already owns `ExcelReportService` and an
`AuditLogger`, and PR #130 established the desired pattern: export the exact
already rendered data, save the file before audit logging, and pass the signed
in user's id to the audit record.

## Goal

Give both reports deterministic Excel exports that exactly match the selected
screen data, give the user accessible progress/success/failure feedback, and
record successful exports in the audit trail.

## Scope

- Procurement: selected period, three rendered summary metrics, and the exact
  supplier-spend entries rendered by the screen.
- Cash movements: selected period, the three rendered totals, and exact
  movement rows in their displayed repository order.
- Deterministic filename prefixes containing report type, selected start/end
  dates, and a timestamp.
- Successful-file-first audit records with export type, period, and row count.
- Localized user-facing labels, tooltips, empty/error text, and feedback.
- Repository, Excel-service, and screen tests for parity, audit logging, empty
  data, disabled/busy actions, and user feedback.

## Non-goals

- No report schema/database migration.
- No change to purchase-order or cash-movement accounting rules.
- No new file picker, cloud upload, PDF output, or cross-report redesign.
- No retroactive audit rows for already exported reports.

## Acceptance criteria

1. Each report has a discoverable, semantic export action that is disabled for
   empty data and prevents duplicate exports while running.
2. Export content reflects exactly the selected range and objects rendered in
   the screen; it does not re-fetch or re-sort report rows.
3. The file exists and is non-empty before a successful audit record is
   written. Failed saves do not claim success or write a success audit event.
4. Audit events include a distinct export type, acting user id, date range,
   and exported row count.
5. File names include a stable report prefix, inclusive period, and timestamp.
6. All new UI strings use both English and Indonesian ARB entries.
7. Existing reports remain usable with no data, asynchronous errors, and
   signed-out test fixtures.

## Platform, migration, rollback, and release

Excel files are saved through the existing `path_provider` Documents location
on Windows and Android. No platform-specific API, permission, or schema change
is introduced. A normal PR revert removes the action and code; previously
saved files and audit logs remain truthful historical records. Release impact
is limited to the standard Windows and Android builds.

## Risks and deferred decisions

- The current app treats a missing test session as user id `1`; this increment
  preserves that established report-export behavior. Authentication-policy
  tightening belongs to the wider partial-workflow audit.
- File-system behavior still requires real Windows/Android smoke testing after
  CI, but service tests will use temporary directories.
