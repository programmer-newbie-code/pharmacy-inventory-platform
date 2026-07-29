# Pharmacy Platform Completion Program Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver all planned pharmacy capabilities through small, independently
testable, releasable PRs.

**Architecture:** Build reliability before features, then shared UI foundations,
then inventory/POS/compliance/reporting. Multi-device sync is isolated behind a
future service boundary and is not coupled to local workflows.

**Tech Stack:** Flutter, drift/SQLite, Riverpod, ARB localization, Google Drive,
GitHub Actions.

---

## Program rules

- One track increment per feature branch and PR.
- Add a schema migration and migration test whenever a table changes.
- Write failing domain/data tests before non-trivial behavior.
- Run generated-code, analyze, coverage, Windows build, Android build, PR CI,
  main CI, then release tag for every completed release.

## Workstream A: Reliability foundation

**Plan dependency:** `2026-07-29-backup-integrity-google-drive-hardening.md`.

- [ ] Complete Tasks 1–6 of the backup plan.
- [ ] Add `test/data/database_migration_test.dart` for each released database
  schema fixture.
- [ ] Add `lib/data/database_health_service.dart` with
  `Future<DatabaseHealth> check()` returning `healthy`, `recoverable`, or
  `unusable`; test corrupt/open failure behavior without deleting data.
- [ ] Release as `fix(backup): preserve complete recoverable pharmacy data`.

## Workstream B: UX foundation

**Plan dependency:** `2026-07-29-pharmacy-workflow-ux-modernization.md` Tasks 1,
2, 5, and 6.

- [ ] Ship responsive shell, role-first dashboard, ARB cleanup, and accessibility
  tests.
- [ ] Create `lib/core/formatters.dart` with `formatIdr(int rupiah)` and
  `formatLocalDate(DateTime value, Locale locale)`; prohibit ad-hoc `Rp` and
  `toStringAsFixed` in widgets through a targeted `rg` check.
- [ ] Release as `feat(ui): prioritize daily pharmacy work by role`.

## Workstream C: Inventory and purchasing

**Files expected:** `lib/data/product_repository.dart`,
`lib/data/stock_batch_repository.dart`, `lib/data/supplier_repository.dart`,
`lib/data/purchase_order_repository.dart`, related inventory/supplier features,
and their tests.

- [ ] Add `stock_adjustments` migration: `id`, `product_id`, `batch_id?`,
  `quantity_delta`, `reason`, `created_by`, `created_at`. Add repository method
  `adjustStock({required int batchId, required int delta, required String reason,
  required int userId})` that rejects `qtyRemaining + delta < 0`.
- [ ] Add receiving test: partial PO receipt creates exactly one batch per received
  line and leaves the PO open until all lines are received.
- [ ] Add reorder test: recommendation equals
  `max(0, threshold + leadTimeDemand - stock - openPurchaseQuantity)`.
- [ ] Build CSV import Tasks 3–4 from UX plan; never create commercial data from
  bundled catalog records.
- [ ] Release as `feat(inventory): make receiving and stock correction traceable`.

## Workstream D: POS and shift safety

**Files expected:** POS, receipt, return, shift feature/repository files and tests.

- [ ] Write test: checkout without active shift returns `ShiftRequiredException`.
- [ ] Write test: a price below cost requires non-empty `overrideReason` and admin
  permission; record both on sale/audit event.
- [ ] Write test: return cannot exceed sold quantity across prior returns.
- [ ] Implement scanner focus, cart editing, payment confirmation, print/share
  receipt, and recovery from printer failure after committed sale.
- [ ] Implement close-shift discrepancy reason and supervisor review status.
- [ ] Release as `feat(pos): protect cashier shifts and sales workflow`.

## Workstream E: Compliance and security

- [ ] Add session timeout provider; test it logs out after configured inactivity
  and prompts re-authentication for user management, restore, and data export.
- [ ] Add password policy validator with tests for length, common-password block,
  and confirmation mismatch.
- [ ] Add audit explorer query API with filters for actor, table/action, record,
  and inclusive date range; test pagination/order.
- [ ] Add controlled-drug test from product creation through sale and receipt;
  missing required prescription metadata blocks completion where policy requires.
- [ ] Release as `feat(compliance): secure sensitive pharmacy actions`.

## Workstream F: Alerts and reports

- [ ] Add alert priority enum and deterministic ordering: expired, expiring,
  failed backup, low stock, open shift.
- [ ] Add report tests for gross revenue, refunds, COGS, gross margin, discounts,
  and cash discrepancy with a known fixture dataset.
- [ ] Add export audit logging and user-visible progress/failure states.
- [ ] Release as `feat(reports): surface pharmacy risks and performance`.

## Workstream G: Integration and mobility

- [ ] Document Google Cloud OAuth setup in `USER_GUIDE.md`: Android package,
  SHA-1/SHA-256 signing keys, consent screen, Drive scope, and Windows redirect
  configuration.
- [ ] Add integration test contract for Drive upload/download client using fake
  transport only; manual smoke checklist covers real account separately.
- [ ] Implement device-transfer checklist after verified restore.
- [ ] Write a separate approved spec before any sync server/code. Required sections:
  auth, operation log, conflict matrix, encryption, idempotency, offline queue,
  migration, cost, privacy, and rollback.
- [ ] Release as `feat(backup): guide verified device transfer`.

## Workstream H: Release operations

- [ ] Add release checklist template under `docs/release/`.
- [ ] Add CI check failing if generated Drift/l10n files differ after generation.
- [ ] Add dependency and license review process; pin GitHub Action SHAs where
  repository policy permits.
- [ ] Add smoke-test checklist for Windows, Android, backup/restore, scanner,
  receipt, and controlled sale.
- [ ] Version bump through PR, then tag only after main CI passes.

## Program completion definition

The program is complete only when all Workstreams A–H have shipped green PRs,
their acceptance tests pass on Windows and Android, user guide tasks are complete,
and the deferred-decision list has either an approved follow-up spec or an explicit
product decision to remain out of scope.
