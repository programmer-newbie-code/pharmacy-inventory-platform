# Shift Supervisor Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an auditable, admin-only supervisor review to closed cashier shifts.

**Architecture:** Extend the existing `CashierShifts` table with nullable review
metadata. Keep persistence validation in `CashierShiftRepository`; keep role
gating/dialog state in `ShiftManagementScreen`; use ARB strings for UI.

**Tech Stack:** Flutter, Drift SQLite migrations, Riverpod, ARB, flutter_test.

---

### Task 1: Persist review metadata safely

**Files:**
- Modify: `lib/data/database.dart`
- Modify: `lib/data/cashier_shift_repository.dart`
- Test: `test/data/cashier_shift_repository_test.dart`
- Test: existing database migration test fixture

- [ ] Write failing tests for admin review of a closed shift, rejection of an
open shift, and migration from schema 10 with an existing historical shift.
- [ ] Bump schema to 11; add nullable `reviewedBy`, `reviewedAt`, and
`reviewNote` columns; add the `from < 11` migration columns.
- [ ] Add `reviewShift(shiftId, reviewedBy, reviewNote)` that verifies closed
status and updates the review metadata atomically.
- [ ] Run generated code and focused repository/migration tests.

### Task 2: Add administrator workflow and localization

**Files:**
- Modify: `lib/features/pos/shift_management_screen.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_id.arb`
- Test: `test/features/pos/shift_management_screen_test.dart`

- [ ] Write failing widget tests for an admin seeing/reviewing an unreviewed
closed shift and a cashier not seeing the action.
- [ ] Add ARB review labels, status, validation, and success/failure messages.
- [ ] Gate the review action by active admin session, collect optional note,
call the repository, invalidate shift data, and render reviewed state.
- [ ] Run focused widget tests.

### Task 3: Verify and deliver

- [ ] Run `flutter gen-l10n`, `dart run build_runner build
--delete-conflicting-outputs`, formatter, analyzer, focused/full coverage tests,
CI-equivalent >=80% coverage, and `flutter build windows`.
- [ ] Restore generated Windows registrant files, inspect diff, create signed
commit/PR with migration evidence, wait for every CI gate, squash merge, and
verify green main CI.
