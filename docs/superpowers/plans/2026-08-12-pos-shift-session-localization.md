# POS Shift Session Attribution and Localization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Attribute POS cash operations to the active session and localize their operational UI.

**Architecture:** Keep session resolution in the feature layer. Repository APIs remain unchanged; the screen and dialog reject a missing session before calling them. ARB owns every message displayed by the changed widgets.

**Tech Stack:** Flutter, Riverpod, Drift repositories, ARB localization, flutter_test.

---

### Task 1: Session-safe shift operations

**Files:**
- Modify: `lib/features/pos/shift_management_screen.dart`
- Modify: `test/features/pos/shift_management_screen_test.dart`

- [ ] Add a failing widget test with an authenticated non-default user and
assert the active-shift lookup and open action use that user. Add a no-session
case asserting no financial action proceeds.
- [ ] Resolve `authSessionProvider` at each shift operation. Replace every
literal cashier ID with `currentUser.id`; for null session, display a localized
message and return before repository invocation.
- [ ] Run `flutter test test/features/pos/shift_management_screen_test.dart`.

### Task 2: Session-safe, localized cash movements

**Files:**
- Modify: `lib/features/pos/cash_movement_dialog.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_id.arb`
- Modify: `test/features/pos/cash_movement_dialog_test.dart`

- [ ] Add failing tests for missing-session rejection and localized rendered
labels/validation text.
- [ ] Replace `currentUser?.id ?? 1` with a guarded active user ID. Replace all
touched hard-coded labels, validation messages, button labels, and snackbars
with ARB keys in both locales.
- [ ] Run `flutter gen-l10n` and the focused cash-movement/shift tests.

### Task 3: Verify and deliver

**Files:**
- Modify: the spec and plan above only if verification changes their evidence.

- [ ] Run `dart format` on changed Dart files; `dart run build_runner build
--delete-conflicting-outputs`; `flutter analyze`; focused tests; full
`flutter test --coverage`; CI-equivalent filtered coverage >=80%; and
`flutter build windows`.
- [ ] Restore regenerated Windows registrant files, run `git diff --check`,
and create a signed `fix(pos): attribute cash operations to active user` commit.
- [ ] Push a fully described PR, monitor every required check, fix exact
failures, squash-merge only green CI, and verify main CI.
