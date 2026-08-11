# Backup integrity and restore-recovery hardening

**Status:** Proposed implementation
**Date:** 2026-08-12

## Evidence and problem

`BackupService.exportDatabaseToJson` emits schema, timestamp, counts, and
data, while `BackupDocument` validates shape, counts, IDs, and references.
Neither local nor Drive backups include a content checksum, so corruption that
preserves valid JSON structure may be accepted. `restoreFromBackupData` parses
before its transaction and uses a transaction for destructive replacement, so
invalid documents do not delete current records; however failed restore
attempts create no recovery log, leaving operators without an audit trail.

## Scope

- Add a backward-compatible SHA-256 checksum of the canonical backup payload.
- Verify it before a restore mutation, while accepting existing schema-v2
  backups without it as legacy documents.
- Record failed restore attempts without changing existing data; retain the
  successful restore log after a transaction.
- Ensure Drive uploads use the same validated export document; no fake
  success entry is permitted when upload or local generation fails.

## Non-goals

- No Google OAuth account testing, remote Drive download/list API, encryption,
  schema migration, password protection, or restore UI redesign.
- No change to the existing atomic data replacement semantics.

## Acceptance criteria

1. Newly created local and Drive JSON documents include a deterministic
   checksum that detects payload tampering before database deletion.
2. A valid legacy v2 backup without a checksum can still preview and restore.
3. Invalid checksum/JSON/reference restores leave existing data unchanged and
   create a `restore` failed log with no false-success row.
4. A successful restore has a non-empty post-restore log only after the
   transaction succeeds.
5. Local/Drive tests cover integrity, legacy compatibility, failed recovery
   logging, and upload success/failure ordering.

## Platform, migration, rollback, and release

This is JSON metadata only. No Drift schema or migration is needed. Windows
and Android both use the same Dart document validator. A revert preserves
existing files; legacy acceptance protects old user backups. Standard build
and backup smoke tests are the release impact.

## Risks and deferred decisions

Checksum detects accidental or unauthenticated tampering but is not encryption
or a trust signature. Real Google OAuth and device restore testing require an
authorized account/device and remain separate external verification.
