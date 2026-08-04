# Indonesian Drug Catalog and CSV Import Plan

## Increment 1: validation and safe commit

1. Add failing data tests for existing internal-code conflicts, malformed and
   non-positive numeric input, malformed `isControlled`, UTF-8 names, and
   rollback when a valid-row write fails.
2. Split parsing/validation from commit in `CsvImportService`; retain the
   preview's skip-existing policy and commit all valid rows transactionally.
3. Run focused tests, `flutter analyze`, full coverage tests, and a Windows
   debug build before PR. Android build remains CI-required when no local SDK
   exists.

## Increment 2: localized staged UI

1. Replace hardcoded CSV dialog strings and raw parser/write errors with ARB
   resources and concise actionable messages.
2. Show separate valid, skipped, and failed-unexpected outcomes; keep the
   catalog warning visible before selection/import.
3. Add widget coverage for preview, invalid rows, picker cancellation, and
   completed outcome at phone and desktop widths.

## Increment 3: catalog provenance and maintenance

1. Document included fields, non-commercial limitations, source status, and
   a repeatable validation/update procedure.
2. Add catalog schema/content tests that prevent a malformed bundled CSV from
   shipping.
3. Add verified BPOM provenance/licensing only after a data owner supplies an
   authoritative source and license.

## Rollout and rollback

No schema migration is needed. The importer is additive. If an unexpected
import error occurs, its transaction rolls back valid rows; users correct the
reported input and retry. Existing manually created products are unchanged.
