# Drive Auto-backup Session Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure an enabled automatic Drive backup records a truthful failure when the in-memory OAuth session is absent.

**Architecture:** Add a small service method that owns the session check and reuses the existing upload/logging path. The scheduler calls that method after its local backup. A directory collaborator makes the scheduler integration deterministic in tests without changing production storage behavior.

**Tech Stack:** Flutter/Dart, Drift/SQLite, SharedPreferences, `flutter_test`.

---

### Task 1: Make the Drive session outcome explicit

**Files:**
- Modify: `lib/data/google_drive_backup_service.dart`
- Test: `test/data/google_drive_backup_service_test.dart`

- [ ] **Step 1: Write failing service tests**

Add tests that call a new `uploadCurrentUserBackupToDrive()` with no signed-in
account and assert a `GoogleDriveBackupResult` with `success == false` plus one
`backupLogs` record having `destination == 'drive'` and `status == 'Failed'`.
Add a signed-in fake-authorizer/upload-client case that asserts the existing
upload receives the account access token and logs `Success`.

- [ ] **Step 2: Run focused tests and observe failure**

Run: `flutter test test/data/google_drive_backup_service_test.dart`

Expected: compilation failure because `uploadCurrentUserBackupToDrive` does not
exist.

- [ ] **Step 3: Implement the minimal service method**

Add `Future<GoogleDriveBackupResult> uploadCurrentUserBackupToDrive()`. If
`currentUser` is null, insert the existing `backupLogs` row with `drive`,
`Failed`, and zero size, then return a failed result. Otherwise call
`uploadBackupToDrive(accessToken: currentUser.accessToken)`. Do not invoke
`signInWithGoogle`, and do not store an access token.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/data/google_drive_backup_service_test.dart`

Expected: PASS.

### Task 2: Connect auto-backup without hiding failures

**Files:**
- Modify: `lib/data/auto_backup_scheduler.dart`
- Test: `test/data/auto_backup_scheduler_test.dart`

- [ ] **Step 1: Write a failing scheduler integration test**

Construct the scheduler with Drive enabled, an in-memory database, and a
temporary-directory collaborator. Start an overdue schedule with no Drive
account, then assert local backup time is recorded and `backupLogs` contains a
failed Drive row.

- [ ] **Step 2: Run focused test and observe failure**

Run: `flutter test test/data/auto_backup_scheduler_test.dart`

Expected: the test cannot inject a deterministic directory or finds no Drive
failure row.

- [ ] **Step 3: Implement the minimal scheduler wiring**

Accept an optional `Future<Directory> Function()? backupDirectoryProvider`;
default it to `getBackupDirectory`. Use it only when creating the local backup.
Replace the nullable-user conditional with
`await _driveBackupService.uploadCurrentUserBackupToDrive()` when Drive is
enabled. Preserve the outer `try/finally` and timestamp order, so a Drive
failure never cancels the local schedule.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/data/auto_backup_scheduler_test.dart`

Expected: PASS.

### Task 3: Verify and ship the isolated increment

**Files:**
- Modify: `docs/superpowers/specs/2026-08-12-drive-auto-backup-session.md`
- Modify: `docs/superpowers/plans/2026-08-12-drive-auto-backup-session.md`

- [ ] **Step 1: Generate derived code and format**

Run: `flutter gen-l10n`; `dart run build_runner build --delete-conflicting-outputs`; `dart format lib/data/auto_backup_scheduler.dart lib/data/google_drive_backup_service.dart test/data/auto_backup_scheduler_test.dart test/data/google_drive_backup_service_test.dart`.

- [ ] **Step 2: Run local gates**

Run: `flutter analyze`; focused tests; `flutter test --coverage`; calculate the
same filtered coverage exclusions as `.github/workflows/ci.yml`; and `flutter
build windows`.

Expected: analyzer clean, tests pass, filtered coverage at least 80%, Windows
build passes.

- [ ] **Step 3: Inspect and commit**

Run: `git diff --check`; restore changed generated Windows plugin registrant
files if any; create a signed commit with
`git commit -S -m "fix(backup): record missing Drive session"`.

- [ ] **Step 4: Create and deliver PR**

Push `fix/drive-auto-backup-reauth`, create a PR with evidence, tests, no
migration, rollback, and real-OAuth limitation. Monitor every required CI job,
fix exact failures, squash-merge only all-green CI, and verify the resulting
main CI before beginning the next dependent increment.
