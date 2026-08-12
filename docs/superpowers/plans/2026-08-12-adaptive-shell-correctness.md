# Adaptive Shell Correctness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:executing-plans or
> superpowers:subagent-driven-development to implement this plan task-by-task.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec:** [`2026-08-12-adaptive-shell-correctness.md`](../specs/2026-08-12-adaptive-shell-correctness.md)

**Goal:** Make the shell correct at all three breakpoints — global actions
reachable, one navigation model, working tablet tier, no dead shell code, no
hard-coded strings — without changing appearance beyond adding the tablet rail.

**Architecture:** `PharmacyShell` becomes the single owner of shell chrome and
workspace state. It selects chrome by breakpoint (bottom bar / rail / sidebar)
while all tiers share one destination list, one permission-gated filter, and one
shell-swap navigation callback. `HomeScreen` is reduced to dashboard content and
receives the shell's navigation callback instead of calling `Navigator.push`.

**Tech Stack:** Flutter, Riverpod, ARB localization, `flutter_test`.

---

## Verification note

No local Flutter/Dart SDK was available when this plan was written (no install;
Flutter Docker image did not fit in 9.4 GB free disk). If the implementing
environment also lacks a toolchain, expect CI to be the first real gate and
budget for fix-forward cycles. **Before writing assertions against any
third-party or framework API behavior, verify that behavior — do not assume it.**
Two CI failures in PR #130 came from exactly that mistake.

## File map

- Modify: `lib/features/home/home_screen.dart` — the whole increment centers here.
- Modify: `lib/core/responsive_layout.dart` — only if a helper is genuinely needed
  by two or more call sites; do not add speculative abstractions.
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb` — finding-6 strings.
- Modify: `lib/features/auth/login_screen.dart`,
  `lib/data/receipt_pdf_service.dart` — `Powered by Programmer Newbie` string.
- Modify: `test/features/home/home_screen_test.dart` — retarget at `PharmacyShell`.
- Modify: `test/features/accessibility_workflow_test.dart` — real keyboard test.

---

### Task 1: Extract the shared destination model

**Step 1: Write the failing test.**

In `test/features/home/home_screen_test.dart`, add a test at 1366x768 asserting
that a non-admin (for example `kasir`) does **not** see
`Key('desktopNavUsers')`/`Key('desktopNavBackup')`, and an `admin` does. This
pins current permission gating before refactoring it.

**Step 2:** Run `flutter test test/features/home/home_screen_test.dart`.
Expected: PASS (this is a characterization test — it must pass before refactor
and keep passing after).

**Step 3:** In `home_screen.dart`, introduce a private destination record/list
built once in `_PharmacyShellState` from the permission flags, e.g.
`({String id, IconData icon, String label, Widget screen})`. Keep it private to
the file. Do not create a new file for one consumer.

**Step 4:** Re-run the test. Expected: PASS unchanged.

**Step 5:** Commit — `refactor(home): extract shared shell destination list`.

### Task 2: Fix the mobile selected-index defect (finding 5)

**Step 1: Write the failing test.** At 390x844, select Alerts via the More
sheet, then assert the `NavigationBar`'s `selectedIndex` is **not** 0 and that
Alerts is reported selected.

**Step 2:** Run it. Expected: FAIL — currently defaults to 0.

**Step 3:** Replace the `_selected == 'pos' ? 1 : ...` chain (lines ~125-129)
with an index lookup against the Task 1 destination list, and include
Alerts/Reports in the model so their selection is representable.

**Step 4:** Run. Expected: PASS.

**Step 5:** Commit — `fix(home): report correct mobile destination selection`.

### Task 3: Make the Dashboard destination work (finding 3)

**Step 1: Write the failing test.** At 1366x768: tap `desktopNavPos`, assert POS
is shown; tap `desktopNavDashboard`, assert the dashboard workspace is shown
again.

**Step 2:** Run. Expected: FAIL — `onTap: () {}` at line ~827 is a no-op.

**Step 3:** Wire Dashboard through the same `_select` path as every other
destination.

**Step 4:** Run. Expected: PASS.

**Step 5:** Commit — `fix(home): make sidebar dashboard destination navigate`.

### Task 4: Unify navigation on the shell model (finding 4)

**Step 1: Write the failing test.** At 1366x768, tap the dashboard's
`Key('navPosBtn')` card, then assert `Key('desktopSidebar')` is **still**
present.

**Step 2:** Run. Expected: FAIL — `_navigate` pushes a route over the shell.

**Step 3:** Give `HomeScreen` an optional `onSelectDestination` callback supplied
by `PharmacyShell`. Primary-destination nav-cards call it; keep `Navigator.push`
only for genuine drill-downs and for dialogs (branding/help stay dialogs).

**Step 4:** Run. Expected: PASS. Also confirm the existing nav-card tests still
pass; update only their navigation expectation, not their business assertions.

**Step 5:** Commit — `fix(home): keep shell visible for primary destinations`.

### Task 5: Add the tablet NavigationRail (finding 8)

**Step 1: Write the failing tests.**
- 800x1280: `NavigationRail` present, `Key('mobileShellNavigation')` absent,
  `Key('desktopSidebar')` absent.
- 768x1024: same.
- 390x844: rail absent, bottom bar present.
- 1366x768: rail absent, sidebar present.

**Step 2:** Run. Expected: FAIL — tablet currently renders the bottom bar.

**Step 3:** Add a `tablet` branch in `_PharmacyShellState.build` rendering a
`NavigationRail` fed by the Task 1 destination list, with
`labelType: NavigationRailLabelType.all` so labels stay visible. Reuse the same
`_select` callback. **Verify `NavigationRail`'s required parameters and
`selectedIndex` null-handling against the Flutter API before asserting on it** —
`selectedIndex` may be null when the current destination is not in the rail.

**Step 4:** Run. Expected: PASS.

**Step 5:** Commit — `feat(home): add tablet navigation rail`.

### Task 6: Restore the global actions (finding 1)

**Step 1: Write the failing tests.** For each of 1366x768, 800x1280, 390x844:
- `Key('logoutButton')` is reachable (on phone, after opening the More sheet)
  and tapping it clears the session.
- `Key('languageToggle')` and `Key('helpButton')` are reachable.
- `Key('brandingButton')` is present for `admin`, absent for `kasir`.

**Step 2:** Run. Expected: FAIL — none are reachable today.

**Step 3:** Move the four actions out of `HomeScreen`'s dead `AppBar` into shell
chrome: desktop sidebar footer and tablet rail trailing area; phone More sheet.
Keep the existing keys so intent is traceable. Preserve each action's current
behavior and permission check exactly.

**Step 4:** Run. Expected: PASS.

**Step 5:** Commit — `fix(home): restore logout, language, help, and branding`.

### Task 7: Delete the unreachable shell branch (finding 2)

**Step 1:** Retarget every test that constructs `HomeScreen()` (non-embedded) at
`PharmacyShell`, in the **same commit** as the deletion so no untested window
exists.

**Step 2:** Delete `HomeScreen`'s `AppBar`, its `_DesktopSidebar` instantiation
(~line 631), its `bottomNavigationBar` (~line 647), the `isDesktop` branch it
guarded, and the `HomeScreen()` self-reference (~line 654). `HomeScreen` keeps
only dashboard content and the `embedded` parameter if still needed after Task 4;
remove `embedded` too if it becomes dead.

**Step 3:** Run the full suite. Expected: PASS.

**Step 4:** Commit — `refactor(home): remove unreachable home shell branch`.

### Task 8: Localize the remaining strings (finding 6)

**Step 1:** Add ARB keys to both locales: one for the branding nav-card subtitle
(currently `'Identitas & Header Struk'`) and one for
`'Powered by Programmer Newbie'`.

**Step 2:** Replace all four call sites — `home_screen.dart:609`,
`home_screen.dart:913`, `login_screen.dart:249`,
`receipt_pdf_service.dart:127`. **Note:** `receipt_pdf_service.dart` is a data-layer
service with no `BuildContext`; pass the localized string in from the caller
rather than importing localization into `lib/data/`, which would break the layering
rule in `AGENT.md`.

**Step 3:** Verify en/id key parity, then run the suite.

**Step 4:** Commit — `localize(home): move shell strings to ARB`.

### Task 9: Real keyboard traversal test (finding 7)

**Step 1:** In `accessibility_workflow_test.dart`, replace the misleading
assertions with a genuine test: send `LogicalKeyboardKey.tab` repeatedly at
1366x768 and assert focus reaches the primary navigation items in visual order,
and that the focused item is visually distinguishable.

**Step 2:** Run. If it fails, add explicit focus affordances (for example
`FocusTraversalOrder`, or a focus-visible decoration on nav items) until it
passes. **Do not weaken the test to make it pass.**

**Step 3:** Add a text-scale 2.0 case at 1366x768 asserting
`tester.takeException()` is null, to catch shell overflow.

**Step 4:** Commit — `test(home): verify shell keyboard traversal and text scale`.

### Task 10: Full verification and PR

- [ ] `dart run build_runner build --delete-conflicting-outputs`, confirm no
  unrelated generated churn is staged.
- [ ] `flutter analyze` — zero issues.
- [ ] `flutter test --coverage`, then the CI-equivalent filtered metric excluding
  `**/*.g.dart`, `lib/l10n/*`, `lib/data/database.dart` — expect >= 80 percent.
- [ ] Windows/Android builds locally if a toolchain exists; otherwise rely on CI
  and say so explicitly in the PR.
- [ ] Signed commits, PR with problem/scope/tests/migration/risks, all required
  checks green, squash merge, verify post-merge main CI.
- [ ] Update `docs/superpowers/status/current-roadmap.md` with the merged
  evidence in a follow-up PR, per the `AGENT.md` handoff routine.

## Out of scope for this plan

Collapsible sidebar, top context bar, responsive density tuning, theme-token
migration, dashboard content redesign, and any other appearance change. Those
need rendered before/after comparison and owner approval, and belong to a
separate visual increment.
