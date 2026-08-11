# Implementation plan: backup integrity and restore recovery

**Spec:** `2026-08-12-backup-integrity-recovery.md`

## Tasks

1. Define canonical checksum generation/validation in `BackupDocument` while
   retaining compatibility with existing v1/v2 documents lacking a checksum.
2. Have `BackupService` write the checksum and validate before entering the
   restore transaction; log recoverable failed restore attempts outside the
   transaction without overwriting current history.
3. Confirm `GoogleDriveBackupService` uploads the common verified document and
   logs success only after its upload client returns.
4. Add document/service/Drive tests for tampering, legacy restore, atomic
   preservation, recovery logs, and upload ordering.
5. Run formatting, generated code/l10n where required, analyzer, focused and
   full tests, filtered coverage, local Windows/Android checks, signed PR,
   full CI, merge, and green-main verification.

## Migration and rollback

No migration. Existing backups remain readable. Reverting removes checksum
verification for new data but does not invalidate existing backup files.
