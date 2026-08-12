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
(lines 94-96 and 211-212). The enum therefore lies about what the shell does:
it advertises three tiers while the shell implements two.

Everything from 600 to 1023 px falls through to the phone branch. The defect is
the dishonest abstraction, not the absence of a third layout — see the
two-tier decision below.

## Required behavior

### Global actions

- Logout, language toggle, help, and branding (branding subject to the existing
  `canManageBranding` permission) are reachable from the shell at every width.
- At >= 1024 px they live in the sidebar. Below 1024 px they live in the existing
  More bottom sheet, keeping the bottom bar at four destinations.
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

**Two tiers, split on width at 1024 px, one navigation model.** Layout branches
on viewport width only — never on host platform — because a 1280 px Windows
window and an Android tablet in landscape are the same layout problem, and
branching on OS would hand an Android tablet a phone UI purely for being
Android.

| Width | Chrome | Devices that land here |
| --- | --- | --- |
| < 1024 | bottom `NavigationBar`, 4 destinations + More sheet | Android phones (360-430); Android tablet portrait (768-820); a Windows window deliberately shrunk below 1024 |
| >= 1024 | existing 248 px `_DesktopSidebar` | Windows at its 1280x720 default launch size (`windows/runner/main.cpp:29`) and above; Android tablet landscape |

Rationale for two tiers rather than three: the product design spec describes
"one Android tablet/phone" under a single-active-device model, and no evidence
exists of tablet use today. A third `NavigationRail` chrome for the
600-1023 px band would serve a hypothetical device while adding a third chrome
variant, a third test matrix, and a third thing to keep in sync. `AGENT.md`
forbids exactly that: "No unrequested abstractions... The smallest diff that
correctly solves the actual requirement wins." Tablet portrait therefore gets
the bottom bar — not ideal use of width, but usable, thumb-reachable, and
consistent — and rotating to landscape promotes it to the sidebar
automatically.

Finding 8 is still fixed, honestly: the shell's two-tier intent becomes
explicit rather than being contradicted by a three-value enum. Either retire the
unused `tablet` value or keep the enum and express the branch as
"`>= desktop` gets the sidebar, everything else gets the bottom bar."

Resizing is live. The shell reads `MediaQuery.sizeOf(context).width` during
build, so dragging the Windows window across 1024 px swaps chrome immediately
with no restart, and Android rotation is handled by the same code path. A
narrow Windows window showing the bottom bar is correct responsive behaviour,
not a regression; a 248 px sidebar cannot coexist with usable content at
~700 px.

- Selected state is correct for every destination on both tiers, including
  destinations reached through the More sheet.
- Permission gating (`canManageUsers`, `canManageBackup`, `canManageSuppliers`,
  `canManageShifts`, `canManageReturns`) applies identically on both tiers.

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
- A dedicated `NavigationRail` chrome for the 600-1023 px band. Deliberately
  excluded as speculative until real tablet-portrait usage is confirmed; revisit
  only with evidence.
- Any layout branch on host platform rather than viewport width.
- Redesigning dashboard content, stats, or nav-card visuals.
- Changing permissions, business logic, repositories, schema, or routes other
  than the shell/workspace mechanism described above.
- Android physical-device verification, which remains external.

## Acceptance criteria

1. A widget test proves logout is reachable and invokes logout from
   `PharmacyShell` both above and below 1024 px.
2. A widget test proves language toggle, help, and branding are reachable at both
   tiers, with branding still hidden for non-admin roles.
3. A widget test at 1366x768 proves the sidebar renders and no bottom
   `NavigationBar` is present; a test at 390x844 proves the bottom bar renders and
   no sidebar is present.
4. A widget test proves the 1024 px boundary behaves as specified: 1023 px gets
   the bottom bar and 1024 px gets the sidebar. A test at 768x1024 documents that
   tablet portrait deliberately receives the bottom bar.
5. Selecting Dashboard after navigating away returns to the dashboard workspace.
6. Selecting any destination, including Alerts and Reports via the More sheet,
   reports that destination as selected rather than defaulting to Dashboard.
7. Navigating to a primary destination from a dashboard nav-card keeps the shell
   chrome visible for that width.
8. A test asserts `Tab` traversal reaches the primary navigation items in visual
   order and that the focused item is distinguishable from the unfocused state.
9. No test constructs the removed non-embedded `HomeScreen` shell; suites assert
   against `PharmacyShell`.
10. No hard-coded user-facing string from finding 6 remains; en and id ARB keys
    stay at parity and generated localization is clean.
11. `AppBreakpoint` no longer advertises a tier the shell does not implement.
12. `flutter analyze` is clean, the full suite passes, CI-filtered coverage stays
    at or above 80 percent, PR CI is green on all required checks, and post-merge
    main CI is green.

## Migration and rollback

No schema, repository, or persisted-data change. Rollback is a code-only revert.
Risk concentrates in shell navigation, which the tests above cover per
breakpoint.

## Verification strategy

Widget tests at 390x844 (phone), 768x1024 (tablet portrait, documenting the
deliberate bottom-bar choice), 1023x768 and 1024x768 (the boundary), and
1366x768 and 1920x1080 (desktop), plus a text-scale case at 2.0 to catch shell
overflow. Rendered Windows/Android confirmation stays a follow-up because no
local Flutter toolchain or device is available in the implementation
environment; CI builds plus the widget matrix are the gate for this increment.

## Risks and controls

- **Shell regression:** both tiers and the 1024 px boundary get explicit
  chrome-presence tests rather than a single desktop assertion.
- **Test churn from removing dead code:** retarget existing `HomeScreen()` tests
  at `PharmacyShell` in the same commit that deletes the branch, so no window
  exists where behavior is untested.
- **Scope creep into visuals:** any change that alters appearance beyond
  relocating existing actions into reachable chrome is out of scope and deferred.
- **Unverified keyboard claims:** finding 7 is treated as unverified until the
  new traversal test passes; the existing misleading test name is corrected.
- **Tablet-portrait ergonomics:** accepted as a known trade-off, recorded here so
  a future agent does not treat it as an undiscovered bug. Revisit only if real
  tablet usage is confirmed.
