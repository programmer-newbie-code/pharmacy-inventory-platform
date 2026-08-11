# Receipt Save and Print Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make receipt save and print failures recoverable without duplicating completed sales.

**Architecture:** Convert `ReceiptDialog` to stateful UI orchestration. It retains PDF generation and storage in the existing data services, but receives optional save/print callbacks for deterministic widget tests. A failed asynchronous operation clears only its busy state and displays an ARB-localized SnackBar with retry.

**Tech Stack:** Flutter, Riverpod, `printing`, ARB localization, Flutter widget tests.

---

## File map

- Modify: `lib/features/pos/receipt_dialog.dart` — async state, recovery UI, localized labels.
- Modify: `lib/l10n/app_en.arb` — English receipt recovery strings.
- Modify: `lib/l10n/app_id.arb` — Indonesian receipt recovery strings.
- Create: `test/features/pos/receipt_dialog_test.dart` — isolated receipt-dialog recovery tests.

### Task 1: Write failing recovery tests

**Files:** `test/features/pos/receipt_dialog_test.dart`

- [ ] Add a fixture with a save callback that throws and expect `receiptSaveFailed` plus the retry action.
- [ ] Add a fixture with a print callback that throws and expect `receiptPrintFailed` plus the retry action.
- [ ] Use a pending completer to prove the corresponding action is disabled while it runs, then complete it and assert the success message.
- [ ] Run `flutter test test/features/pos/receipt_dialog_test.dart` and confirm the tests fail before implementation because errors escape the current callbacks.

### Task 2: Implement minimal recovery behavior

**Files:** `lib/features/pos/receipt_dialog.dart`

- [ ] Convert `ReceiptDialog` to `ConsumerStatefulWidget` and add independent `_isSaving` and `_isPrinting` state.
- [ ] Add optional save and print callback parameters used only by tests; production defaults must continue to call `ReceiptPdfService`, `ReceiptStorageService`, and `Printing.layoutPdf`.
- [ ] Wrap each operation in `try`/`catch`/`finally`; on failure retain the dialog, suppress the raw exception, show the matching localized SnackBar, and attach `retryButton` to the same handler.
- [ ] Disable only the action being performed and preserve the successful save-path message.

### Task 3: Localize the touched receipt controls

**Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`, `lib/features/pos/receipt_dialog.dart`

- [ ] Add `receiptSaveFailed` and `receiptPrintFailed` with equivalent English and Indonesian text.
- [ ] Replace touched hard-coded receipt action labels with `transactionReceipt`, `printReceipt`, and `doneButton` accessors.
- [ ] Run `flutter gen-l10n` and confirm generated accessors compile.

### Task 4: Verify and deliver

**Files:** all files above

- [ ] Run `dart format` on modified Dart files and `flutter test test/features/pos/receipt_dialog_test.dart`.
- [ ] Run `flutter analyze`, `flutter test --coverage`, and the CI-equivalent filtered coverage calculation; require at least 80% coverage.
- [ ] Run `flutter build windows`; verify the Release executable exists. Android build remains GitHub CI because the local Android SDK is unavailable.
- [ ] Inspect `git diff --check`, restore generated Windows plugin files if modified, sign the commit, push, create a PR with validation and physical-printer limitations, wait for every CI check, squash merge, verify main CI, and refresh roadmap status.

## Self-review

- Tasks 1–3 map to every acceptance criterion in the spec.
- The work intentionally changes no sale, receipt PDF, database, or print-plugin contract.
- The retry callbacks and busy flags are owned by the dialog, so data-service types remain unchanged.
