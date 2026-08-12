# Adaptive Shell Correctness

Child increment of
[`cross-agent modernization roadmap`](2026-08-12-cross-agent-modernization-roadmap.md)
Priority 2 (Windows desktop modernization) and Priority 3 (Android mobile
modernization). This increment covers **objective correctness only**. Subjective
visual refinement (collapsible sidebar, top context bar, density, theme tokens)
is deferred to a separate increment that requires rendered comparison and owner
approval.

## Evidence

Audited by static trace of `lib/features/home/home_screen.dart` (1299 lines),
`lib/main.dart`, `lib/core/responsive_layout.dart`,
`test/features/home/home_screen_test.dart`, and
`test/features/accessibility_workflow_test.dart` at commit `529f575`.

No Flutter SDK was available in the audit environment (no local install; the
`ghcr.io/cirruslabs/flutter:stable` image did not fit in 9.4 GB free disk), so
findings 1-6 and 8 were established by static reachability tracing, which is
conclusive for them. Finding 7 is explicitly labelled unverified and must be
confirmed by the tests this increment adds.

### 1. Logout and three other global actions are unreachable in production

`main.dart:49` routes every logged-in user to `PharmacyShell`. `PharmacyShell`
renders `HomeScreen(embedded: true)` (lines 78 and 98). `HomeScreen` builds its
`AppBar` only when `embedded == false` (line 215). The logout, language-toggle,
branding, and help actions exist only inside that `AppBar` (lines 222-261).

`ref.read(authSessionProvider.notifier).logout()` is called from exactly one
place in `lib/` — `home_screen.dart:260` — so **a logged-in user cannot sign
out, change language, open branding, or open the quick guide at any window
size.**

### 2. Roughly 250 lines of unreachable shell code

`HomeScreen`'s non-embedded branch (its own `AppBar`, a second
`_DesktopSidebar` instantiation at line 631, its own `bottomNavigationBar` at
line 647, and the `HomeScreen()` self-reference at line 654) can never render in
production. It is kept compiling by tests that construct `HomeScreen()`
directly, so part of the existing widget-test suite asserts against a shell
users never see.

### 3. The sidebar Dashboard item does nothing

`home_screen.dart:827` is `onTap: () {}`. After navigating to any other
destination there is no way to return to the dashboard from the sidebar.

### 4. Two contradictory navigation models

The sidebar swaps the workspace with `setState` (lines 81-86), keeping the
shell. The dashboard nav-cards call `_navigate` (line 688), which is
`Navigator.push` of a full-screen route that **covers the sidebar**. The same
destination therefore behaves differently depending on entry point, and
card-entry loses the persistent shell. This contradicts the parent spec's
"Primary destinations keep the shell; Back is reserved for drill-down flows."

### 5. Mobile selected-destination state is wrong

`PharmacyShell` lines 125-129 map only `pos`→1 and `inventory`→2, defaulting
everything else to 0. Selecting Alerts or Reports leaves the bar highlighting
Dashboard.

### 6. Hard-coded user-facing strings

- `home_screen.dart:609` — `'Identitas & Header Struk'`, hard-coded Indonesian
  shown to English users.
- `'Powered by Programmer Newbie'` is hard-coded in `home_screen.dart:913`,
  `login_screen.dart:249`, and `receipt_pdf_service.dart:127`, with no ARB key.

`AGENT.md` requires all user-facing strings to come from ARB.

### 7. Keyboard operability is asserted but not actually tested (unverified)

`accessibility_workflow_test.dart`'s first test is named "...and keyboard
operable" but only asserts one semantics label, one height >= 48, and a `tap`.
There is no `Tab` traversal, focus-order, or focus-visibility assertion. Sidebar
items are bare `ListTile`s inside `Semantics`, with no explicit traversal order
and no verified focus indicator against the dark `0xFF073F3B` surface.

### 8. The tablet breakpoint is defined, unit-tested, and never used

`AppBreakpoint.tablet` exists in `lib/core/responsive_layout.dart` and
`test/core/responsive_layout_test.dart` asserts `fromWidth(800) ==
AppBreakpoint.tablet`, but the shell only ever compares `== AppBreakpoint.desktop`
(lines 94-96 and 211-212). Every 600-1023 px viewport therefore falls through to
the phone branch:

| Width | `fromWidth` result | Shell actually renders |
| --- | --- | --- |
| < 600 | phone | bottom `NavigationBar` (correct) |
| 600-1023 | tablet | bottom `NavigationBar` (**wrong**) |
| >= 1024 | desktop | 248 px sidebar (correct) |

iPad portrait (768), iPad Air (820), and common 10-inch Android tablets (800)
all receive the four-destination phone bar plus a More sheet while more than
700 px of horizontal space goes unused.

## Required behavior

### Global actions

- Logout, language toggle, help, and branding (branding subject to the existing
  `canManageBranding` permission) are reachable from the shell at every
  breakpoint.
- Desktop and tablet expose them in shell chrome. Phone exposes them in the
  existing More bottom sheet, keeping the bottom bar at four destinations.
- Behavior of each action is unchanged; only reachability changes.

### Navigation model

- Primary destinations always swap the workspace **inside** the shell, never
  push over it. This applies to sidebar items, rail items, bottom-bar items, and
  dashboard nav-cards, so a destination behaves identically regardless of entry
  point.
- Drill-down flows (for example product detail, receiving a specific purchase
  order) continue to use `Navigator.push`. `Back` remains reserved for those.
- The Dashboard destination is selectable and returns to the dashboard
  workspace.

### Adaptive chrome

Three tiers, one navigation model, differing only in how the destination picker
renders:

| Breakpoint | Chrome | Rationale |
| --- | --- | --- |
| phone (< 600) | bottom `NavigationBar`, 4 destinations + More sheet | thumb reach; no room for persistent navigation |
| tablet (600-1023) | `NavigationRail` showing all permitted destinations | persistent visibility without spending 248 px |
| desktop (>= 1024) | existing 248 px `_DesktopSidebar` | unchanged |

- Selected state is correct for every destination on every tier, including
  destinations reached through the More sheet.
- Permission gating (`canManageUsers`, `canManageBackup`, `canManageSuppliers`,
  `canManageShifts`, `canManageReturns`) applies identically on all three tiers.

### Code health

- The unreachable non-embedded `HomeScreen` shell branch is removed, and tests
  that depended on it are retargeted at `PharmacyShell`, the shell users
  actually get.
- `HomeScreen` becomes dashboard content only; it no longer builds shell chrome.
- All strings named in finding 6 are moved to `app_en.arb` and `app_id.arb`.

## Non-goals

- Collapsible sidebar, top context bar, density changes, theme-token migration,
  and any other subjective visual change. These require rendered comparison and
  owner approval, and belong to the follow-up visual increment.
- Redesigning dashboard content, stats, or nav-card visuals.
- Changing permissions, business logic, repositories, schema, or routes other
  than the shell/workspace mechanism described above.
- Android physical-device verification, which remains external.

## Acceptance criteria

1. A widget test proves logout is reachable and invokes logout from
   `PharmacyShell` at desktop, tablet, and phone widths.
2. A widget test proves language toggle, help, and branding are reachable at all
   three widths, with branding still hidden for non-admin roles.
3. A widget test at 800x1280 proves a `NavigationRail` renders and no bottom
   `NavigationBar` is present.
4. A widget test at 1366x768 proves the sidebar renders and no rail is present;
   a test at 390x844 proves the bottom bar renders and no rail is present.
5. Selecting Dashboard after navigating away returns to the dashboard workspace.
6. Selecting any destination, including Alerts and Reports via the More sheet,
   reports that destination as selected rather than defaulting to Dashboard.
7. Navigating to a primary destination from a dashboard nav-card keeps the shell
   chrome visible for that breakpoint.
8. A test asserts `Tab` traversal reaches the primary navigation items in visual
   order and that the focused item is distinguishable from the unfocused state.
9. No test constructs the removed non-embedded `HomeScreen` shell; suites assert
   against `PharmacyShell`.
10. No hard-coded user-facing string from finding 6 remains; en and id ARB keys
    stay at parity and generated localization is clean.
11. `flutter analyze` is clean, the full suite passes, CI-filtered coverage stays
    at or above 80 percent, PR CI is green on all required checks, and post-merge
    main CI is green.

## Migration and rollback

No schema, repository, or persisted-data change. Rollback is a code-only revert.
Risk concentrates in shell navigation, which the tests above cover per
breakpoint.

## Verification strategy

Widget tests at 390x844 (phone), 768x1024 and 800x1280 (tablet), and 1366x768
and 1920x1080 (desktop), plus a text-scale case at 2.0 to catch shell overflow.
Rendered Windows/Android confirmation stays a follow-up because no local Flutter
toolchain or device is available in the implementation environment; CI builds
plus the widget matrix are the gate for this increment.

## Risks and controls

- **Shell regression:** every breakpoint gets explicit chrome-presence tests
  rather than a single desktop assertion.
- **Test churn from removing dead code:** retarget existing `HomeScreen()` tests
  at `PharmacyShell` in the same commit that deletes the branch, so no window
  exists where behavior is untested.
- **Scope creep into visuals:** any change that alters appearance beyond adding
  the rail and relocating existing actions is out of scope and deferred.
- **Unverified keyboard claims:** finding 7 is treated as unverified until the
  new traversal test passes; the existing misleading test name is corrected.
