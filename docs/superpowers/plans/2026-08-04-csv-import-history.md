# CSV import history plan

## Increment 1: durable data and service summary

1. Add `CsvImportLogs` and schema version 4 migration.
2. Extend `CsvImportService.importPreview` with source/user metadata and write
   one transactional summary row for success or rollback failure.
3. Add repository/query helpers and tests for migration, counts, ordering, and
   rollback.

## Increment 2: backup and UI

1. Include import history in validated backup JSON and atomic restore while
   accepting older backups that omit the optional collection.
2. Render newest import outcomes in the inventory import dialog with localized
   labels and bounded error details.
3. Add widget coverage and verify local Windows build plus CI Android build.

Each increment is a separate signed PR from green `origin/main`.
