# Receipt Save and Print Recovery Design Spec

## Current-state evidence

`ReceiptDialog` calls `ReceiptStorageService.saveReceiptPdf` and `Printing.layoutPdf` directly from button callbacks. Both operations can throw, but neither callback catches errors, disables duplicate taps, or offers retry. Existing storage tests verify successful writes and path sanitization; they do not cover the UI recovery path.

## Scope

- Keep a receipt dialog open after a save or print failure.
- Disable only the action currently in progress, preventing duplicate file writes or duplicate print dialogs.
- Show localized, non-technical save/print failure messages with a retry action.
- Preserve the existing successful PDF save path and native print workflow.
- Localize the receipt dialog's operational labels touched by this workflow.

## Non-goals

- No printer discovery, printer selection, print queue persistence, or retry after the dialog is closed.
- No receipt schema, sale, audit, or storage-location migration.
- No change to generated PDF contents or the native `printing` plugin contract.

## Acceptance criteria

1. A successful save still reports the returned path only after the file is written.
2. A save failure leaves the dialog usable, shows a localized recovery message, and offers retry without exposing the raw exception.
3. A print failure leaves the dialog usable, shows the same style of recovery, and offers retry.
4. Save and print cannot be invoked repeatedly while their respective operation is in progress.
5. New user-facing strings are present in both `app_en.arb` and `app_id.arb`.
6. Widget tests cover success, save failure, print failure, retry, and busy button state; storage success tests remain green.

## Platform behavior

Windows and Android both use the same dialog. A save failure commonly means an unavailable/custom receipt directory; a print failure comes from the native print integration. In both cases the sale is already complete and must not be rolled back.

## Data, migration, rollback, and release impact

No database or persisted-data change. Reverting is code-only. Release artifacts need normal Windows and Android CI builds because this calls platform print APIs.

## Risks and deferred decisions

Native printer availability cannot be fully simulated in widget tests. Tests will inject the save/print actions so recovery behavior is deterministic; a physical-printer smoke test remains a release verification item.
