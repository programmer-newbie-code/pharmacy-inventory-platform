# Classic sales Excel export audit parity

**Status:** Proposed implementation
**Date:** 2026-08-12

## Evidence and problem

`ReportsScreen._exportExcel` reads the active range and rendered sales rows,
then calls `ExcelReportService.exportAndSaveReport` directly. The save is
real, but the path does not call `ReportRepository.logExport`; therefore a
successful classic sales export has no acting-user or filter-context audit
record. Best-selling (PR #130), procurement, and cash movement (PR #132) use
save-before-audit repository paths, so this is a verified parity gap.

## Scope

- Move the classic sales save path behind a `ReportRepository` export method.
- Preserve the active inclusive range and supplied row order; do not re-query
  within a widget or add per-row widget database work.
- Save a non-empty file before logging a distinct audit event with user id,
  period, transaction count, and line-row count.
- Keep current localized busy/success/failure behavior and add focused tests.

## Non-goals

- No report-accounting redesign, schema migration, file-picker/cloud upload,
  retroactive audit entries, or changes to SIPNAP/prescription CSV behavior.
- SIPNAP and prescription exports will be audited independently.

## Acceptance criteria

1. A successful classic sales export has an on-disk, non-empty XLSX before its
   audit event is written.
2. The audit event has a distinct action, the active user id, and auditable
   inclusive date-range and count context.
3. Failed saves produce no success audit event or success UI message.
4. The screen passes its already-rendered summary/rows/range to the repository
   and preserves busy/feedback behavior.
5. Repository and widget tests cover success and failure ordering.

## Platform, migration, rollback, and release

Windows and Android continue to use the existing Documents-directory export
service. No schema, migration, or retained user data changes. Reverting the
PR removes the code path only; already created files and audit events remain
truthful historical records. Standard Windows/Android builds are the release
impact.

## Risks and deferred decisions

The existing signed-out test fallback uses user id `1`; this increment keeps
that established behavior. Authentication policy, physical file-system smoke
tests, SIPNAP, and prescription CSV audit parity are explicitly deferred.
