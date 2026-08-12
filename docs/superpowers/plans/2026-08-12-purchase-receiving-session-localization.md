# Purchase Receiving Session and Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:test-driven-development` and follow the repository PR/CI gates.

**Goal:** Prevent signed-out purchase receiving mutations and fully localize the
receiving workflow without changing inventory reconciliation.

**Architecture:** Keep session enforcement in the screen before constructing
repository inputs. Reuse `authSessionProvider`, `sessionRequired`, existing
ARB generation, and the current repository transaction.

**Tech Stack:** Flutter, Riverpod, Drift, ARB localization, widget tests.

### Task 1: Prove and remove the unsafe fallback

**Files:**
- Modify: `test/features/suppliers/purchase_receiving_screen_test.dart`
- Modify: `lib/features/suppliers/purchase_receiving_screen.dart`

- [x] Add a signed-out widget test that enters a valid batch, attempts
  completion, expects `sessionRequired`, and proves no receiving record or PO
  status mutation.
- [x] Run the focused test and confirm it fails because fallback id `1`
  persists the receipt.
- [x] Read the session once at the start of processing, return with localized
  feedback when absent, and pass the non-null id to the repository.
- [x] Run the focused tests and confirm signed-out protection plus authenticated
  attribution pass.

### Task 2: Localize the complete receiving screen

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_id.arb`
- Modify: `lib/features/suppliers/purchase_receiving_screen.dart`
- Modify: `test/features/suppliers/purchase_receiving_screen_test.dart`

- [x] Add a failing Indonesian widget test for representative receiving copy.
- [x] Add paired ARB messages and placeholder metadata for every user-visible
  string owned by the screen.
- [x] Replace hard-coded strings with `AppLocalizations`; use a generic safe
  localized failure message.
- [x] Run `flutter gen-l10n`, format changed Dart, and confirm focused tests
  pass in English and Indonesian.

### Task 3: Verify and deliver

- [x] Run `dart run build_runner build --delete-conflicting-outputs`.
- [x] Run `flutter analyze`.
- [x] Run `flutter test --coverage` and enforce CI-equivalent filtered coverage
  of at least 80%.
- [x] Run `flutter build windows`; require Android CI because local Android SDK
  is unavailable.
- [x] Run `git diff --check` and restore unrelated generated platform files.
- [ ] Create signed commit, complete PR description, and screenshots if copy
  changes materially affect layout.
- [ ] Wait for every PR check, squash-merge only green, verify exact main CI,
  then update `docs/superpowers/status/current-roadmap.md`.
