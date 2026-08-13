# Implementation plan: classic sales Excel export audit parity

**Spec:** `2026-08-12-sales-export-audit-parity.md`

## Tasks

1. Add a repository export method taking the already-rendered sales summary,
   detailed rows, inclusive range, and acting user id.
2. Save through `ExcelReportService`, verify the resulting file is non-empty,
   then write the distinct export audit record with filter/count context.
3. Route `ReportsScreen` through the repository while retaining its localized
   busy, success, and failure UI states.
4. Add repository tests for save-before-audit and no audit on failure, plus a
   widget regression test for the screen interaction.
5. Run formatting, l10n/codegen if needed, analyzer, focused/full tests,
   CI-equivalent coverage, and available Windows/Android validation. Push a
   signed, fully described PR; wait for every CI gate, merge, and verify main.

## Test matrix

| Area | Evidence |
| --- | --- |
| Repository | file exists/non-empty before audit; action/user/range/count details |
| Failure | throwing/empty save leaves no audit row and no success result |
| Screen | active range and signed-in user are forwarded without a second query |
| Regression | existing report filters and Excel output remain usable |

## Migration, rollback, and release

No migration. A revert is code-only; saved files and truthful audit records
remain. Release validation is the standard Windows and Android CI build.
