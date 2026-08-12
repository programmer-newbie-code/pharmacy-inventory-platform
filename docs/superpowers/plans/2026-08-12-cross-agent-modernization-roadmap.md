# Cross-Agent Product Modernization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver the approved branding, platform UX, accessibility, documentation, Play-readiness, and critical-correctness roadmap through evidence-based PR increments that any agent can resume.

**Architecture:** `AGENT.md` provides routing and delivery invariants, the umbrella spec defines product intent, this plan defines sequencing, and `docs/superpowers/status/current-roadmap.md` holds live evidence. Each implementation workstream gets its own child spec and plan before code; completed PRs update the live status rather than rewriting history.

**Tech Stack:** Flutter, Dart, Drift/SQLite, Riverpod, ARB localization, Windows, Android, Jekyll/GitHub Pages, GitHub Actions, Google Play Console.

---

## Canonical files

- `AGENT.md`: mandatory startup and PR/CI rules.
- `docs/superpowers/specs/2026-08-12-cross-agent-modernization-roadmap.md`: approved scope and acceptance criteria.
- `docs/superpowers/plans/2026-08-12-cross-agent-modernization-roadmap.md`: dependency order and PR increments.
- `docs/superpowers/status/current-roadmap.md`: mutable handoff state and evidence.
- Child specs/plans: exact behavior and implementation steps for one workstream.

## Dependency order

`Context -> Brand approval -> Brand integration -> Windows UX -> Android UX -> Accessibility/docs completion -> Play readiness -> Final audit/release`

Critical correctness increments may interrupt this order only for a reproduced
high-impact defect. They still use a child spec/plan and the full delivery gates.

### Task 0: Establish the durable handoff contract

**Files:**
- Modify: `AGENT.md`
- Create: `docs/superpowers/specs/2026-08-12-cross-agent-modernization-roadmap.md`
- Create: `docs/superpowers/plans/2026-08-12-cross-agent-modernization-roadmap.md`
- Create: `docs/superpowers/status/current-roadmap.md`

- [x] Verify `origin/main`, open/recent PRs, and main CI before writing.
- [x] Record the verified baseline and superseded priorities in the live status.
- [x] Add the startup/handoff routing section to `AGENT.md`.
- [x] Run link/path, placeholder, contradiction, and `git diff --check` reviews.
- [x] Commit with a signed `docs(roadmap): establish cross-agent handoff` commit.
- [x] Create a complete PR, wait for every required check, squash-merge, and
  verify the exact post-merge main CI before Task 1.

### Task 1: Create and approve the brand direction

**Files:**
- Create: `docs/superpowers/specs/2026-08-12-professional-branding-icon.md`
- Create: `docs/superpowers/plans/2026-08-12-professional-branding-icon.md`
- Create: visual comparison assets in an increment-specific reviewed location
- Inspect: `assets/branding/app_icon.png`
- Inspect: `windows/runner/resources/app_icon.ico`
- Inspect: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Inspect: `pubspec.yaml`

- [ ] Audit current assets, platform constraints, and any later branding PRs.
- [ ] Define at least three meaningfully different icon directions, small-size
  tests, adaptive-mask behavior, monochrome behavior, and brand non-goals.
- [ ] Render a labeled comparison at taskbar/launcher and store-listing sizes.
- [ ] Obtain owner approval for one direction; do not integrate before approval.
- [ ] Update the child spec with the approved direction and exact asset matrix.
- [ ] Deliver the approved spec/visual decision through its reviewed PR if the
  implementation is intentionally separated.

### Task 2: Integrate approved branding assets

**Files:**
- Modify: `assets/branding/app_icon.png`
- Modify: `windows/runner/resources/app_icon.ico`
- Modify: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Modify/Create: Android adaptive icon resources under `android/app/src/main/res/`
- Modify: `pubspec.yaml`
- Modify: applicable `docs_site` favicon/brand assets
- Test: add asset/config verification identified by the child plan

- [ ] Generate the exact approved Windows, Android, docs, and Play asset set.
- [ ] Verify padding, alpha, adaptive masks, light/dark backgrounds, and small sizes.
- [ ] Run analyzer/tests/coverage and Windows build; require Android CI if no local SDK.
- [ ] Attach rendered comparison evidence to the PR and wait for owner approval.
- [ ] Merge only after approval and all checks; verify post-merge main CI.

### Task 3: Modernize the Windows shell in reviewable increments

**Files:**
- Create: `docs/superpowers/specs/2026-08-12-windows-desktop-modernization.md`
- Create: `docs/superpowers/plans/2026-08-12-windows-desktop-modernization.md`
- Primary implementation: `lib/features/home/home_screen.dart`
- Supporting theme/layout: existing files under `lib/core/`
- Tests: `test/features/home/home_screen_test.dart`, relevant accessibility tests

- [ ] Audit current persistent shell, routes, selection, keyboard focus, and
  representative 1366x768 and 1920x1080 renders.
- [ ] Present shell/density alternatives and obtain owner approval.
- [ ] Split implementation into shell/navigation first, then high-frequency screen
  adaptations; each PR must preserve business behavior and show before/after renders.
- [ ] Verify keyboard traversal, focus visibility, text scaling, no overflow, and
  primary-versus-drill-down Back behavior for each increment.
- [ ] Complete every PR through green main before starting its dependent slice.

### Task 4: Modernize Android navigation and high-frequency flows

**Files:**
- Create: `docs/superpowers/specs/2026-08-12-android-mobile-modernization.md`
- Create: `docs/superpowers/plans/2026-08-12-android-mobile-modernization.md`
- Primary shell: `lib/features/home/home_screen.dart`
- Flow files: current POS, inventory/product, scanner, and receiving feature files
- Tests: corresponding widget/accessibility tests

- [ ] Audit task frequency, bottom/overflow navigation, safe areas, keyboard
  behavior, touch targets, and 360x640/typical modern phone renders.
- [ ] Present navigation and workflow alternatives and obtain owner approval.
- [ ] Deliver navigation shell, POS/scanner, and product/receiving improvements as
  separate complete PRs with rendered evidence.
- [ ] Verify semantics, touch sizes, text scaling, validation, interruption recovery,
  and loading/empty/error/retry states in every affected flow.

### Task 5: Close accessibility, localization, and docs-site gaps

**Files:**
- Create focused child specs/plans per independent gap
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`
- Modify: only affected widgets/tests
- Modify: `docs_site/index.md`, `docs_site/assets/css/style.scss`, or current gallery files as evidence requires

- [ ] Sweep only the screens touched by the roadmap, plus confirmed operational
  hard-coded strings, and record exact findings.
- [ ] Fix each independent accessibility/localization gap with focused tests.
- [ ] Inspect the published GitHub Pages gallery at desktop and mobile widths.
- [ ] Fix only confirmed overlap/overflow and verify the deployed result after merge.

### Task 6: Prepare Google Play repository artifacts

**Files:**
- Create: `docs/superpowers/specs/2026-08-12-google-play-readiness.md`
- Create: `docs/superpowers/plans/2026-08-12-google-play-readiness.md`
- Modify: Android/build/release configuration only after application-ID and signing decisions
- Create: versioned public store-copy, privacy, data-safety evidence, testing, and rollback documents under `docs/`

- [ ] Audit package identity, permissions, data flows, authentication, network/Drive
  behavior, signing configuration, versioning, and release workflow from code.
- [ ] Present any irreversible package-ID or signing-custody decision to the owner.
- [ ] Prepare declarations and store copy from evidence without submitting them.
- [ ] Build and verify the AAB process without committing signing secrets.
- [ ] Prepare internal/closed-test instructions and owner-only Play Console checklist.

### Task 7: Fix confirmed critical correctness gaps

**First child increment:** purchase-receiving session attribution and localization.

**Files:**
- Create: focused child spec and plan
- Modify: `lib/features/suppliers/purchase_receiving_screen.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`
- Test: `test/features/suppliers/purchase_receiving_screen_test.dart`

- [ ] Reconfirm current main and later PRs have not fixed the gap.
- [ ] Add failing tests proving a missing session creates no receiving record and an
  authenticated receiver is recorded without fallback ID `1`.
- [ ] Localize validation, title, header, line-item, empty, success, and safe failure states.
- [ ] Preserve existing partial-receiving reconciliation behavior.
- [ ] Run full gates and deliver through green PR and green post-merge main CI.
- [ ] Add later critical defects only when reproducible evidence exists.

### Task 8: Final audit and release

**Files:**
- Update: `docs/superpowers/status/current-roadmap.md`
- Update: release/version documentation as evidence requires

- [ ] Prove every approved requirement with code, tests, renders, CI, deployed docs,
  or an explicit external-blocked record.
- [ ] Verify final main Windows and Android CI builds.
- [ ] Create the next appropriate signed `v*` tag only when no approved repository
  work remains.
- [ ] Verify Windows and Android release artifacts and record links/evidence.

## Per-increment delivery checklist

- [ ] Fetch and verify green `origin/main`; inspect open/recent PRs and CI.
- [ ] Create an isolated worktree and correctly named branch.
- [ ] Write/update the focused child spec and plan before implementation.
- [ ] Add tests first for changed behavior where applicable.
- [ ] Run formatting/generation/l10n, analyzer, focused/full tests, filtered coverage
  >=80%, `git diff --check`, and applicable builds.
- [ ] Restore unrelated generated/editor files and preserve user changes.
- [ ] Create signed commit(s), push, and open a fully described PR.
- [ ] Monitor exact required checks; fix forward from failure logs.
- [ ] Squash-merge only when every required check is green.
- [ ] Verify exact post-merge main CI and update the live status immediately.

## Plan self-review result

- Every umbrella-spec scope item maps to Tasks 1-8.
- Independent Windows, Android, brand, Play, docs/accessibility, and correctness
  workstreams require focused child specs/plans rather than one oversized code PR.
- No implementation depends on chat history; current evidence lives in the stable
  status file and GitHub state.
- No credentials, private identity data, signing secrets, legal submission, or
  publication action is delegated to agents.
