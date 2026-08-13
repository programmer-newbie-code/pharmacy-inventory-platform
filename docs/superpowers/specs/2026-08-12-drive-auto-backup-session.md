# Drive Auto-backup Session Recovery

## Current-state evidence

`AutoBackupScheduler._performBackup` preserves `autoBackupDriveEnabled` across
restarts but uploads only when `GoogleDriveBackupService.currentUser` is
non-null. The account is in memory only, so a restarted app can create and log
a local backup while silently skipping the enabled Drive upload. The history
therefore gives no Drive failure/re-authentication signal.

## Scope

- Make an enabled automatic Drive upload produce either a real upload record or
  a failed Drive backup-log record.
- Keep local backup creation, rotation, and scheduling independent of Drive
  session availability.
- Require a new interactive sign-in from the existing Backup screen after a
  restart; background work must not open OAuth consent or persist access tokens.
- Cover the no-session failure and the signed-in success path with tests.

## Non-goals

- OAuth credential configuration, refresh-token storage, real-account testing,
  Drive download/listing, or changing local-backup retention.
- Claiming that a failed automatic upload was retried or uploaded later.

## Acceptance criteria

1. An auto-backup with Drive enabled and no active account writes a `drive` /
   `Failed` backup log entry; it does not fabricate a success entry.
2. A signed-in auto-backup still delegates to the existing upload flow and
   preserves its success/failure logging.
3. A Drive failure does not prevent the local backup, timestamp, rotation, or
   future timer runs.
4. The existing Backup log presents the result through its normal destination
   and status fields; users can re-authenticate with the existing Drive action.
5. No OAuth token is written to preferences and no background sign-in is
   attempted.

## Platform, migration, rollback, and release impact

Behavior is identical on Windows and Android because the scheduler uses the
shared data layer. No schema migration or data deletion is required: the
existing `backup_logs` table stores the failure. Rolling back removes only the
additional failure record behavior. Real-account verification remains blocked
on authorized Google Cloud credentials and account consent.

## Test plan

Use the in-memory Drift database and a fake Drive upload client to verify the
service logs a failed Drive attempt without an account and uploads with an
active account. Exercise the scheduler with a deterministic temporary backup
directory, then run formatter, analyzer, focused tests, full coverage using
the CI exclusions, and Windows build before opening the PR.
