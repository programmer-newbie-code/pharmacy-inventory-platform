# Cross-Agent Product Modernization Roadmap

## Purpose

Agents working in different sessions or models need one durable product
direction and one evidence-based handoff path. Chat history is not authoritative.
The repository must explain what is shipped, what is next, what requires product
approval, and which delivery gates must be completed before another increment
starts.

## Current-state evidence

- `origin/main` is `be43c59`, the merge commit for PR #145.
- Main CI run `31547201220` completed successfully for that commit.
- No PR was open when this roadmap was created.
- PRs #125 through #145 delivered receipt/media work, report exports, scanner
  lifecycle handling, receiving attribution, backup integrity, Drive recovery,
  POS session attribution, and shift supervisor review.
- `lib/features/home/home_screen.dart` already contains responsive desktop and
  mobile shells. The approved work is refinement and visual verification, not a
  replacement built without evidence.
- Windows, Android, and MSIX icon assets exist, but the professional brand and
  replacement icon still require visual exploration and owner approval.
- `docs_site` contains desktop and Android screenshots; published responsive
  overlap remains a verification target.
- `lib/features/suppliers/purchase_receiving_screen.dart` still falls back to
  user ID `1` and contains hard-coded operational strings. This is a proven
  critical-correctness/localization gap distinct from the narrower attribution
  work merged in PR #137.
- Android application ID is currently
  `com.programmernewbiecode.pharmacy_inventory_platform`; Play identity,
  signing, store metadata, and policy evidence are not yet approved as a final
  publication package.

## Product direction

The proposed publisher brand is **ProgrammerNewbie Studio**. Pharmacy Inventory
Platform should feel trustworthy and operationally clear, with a modern visual
identity that works across Windows, Android, documentation, and Google Play.
The brand must not depend on permanent ownership of `programmer-newbie.dev`.

Windows and Android share terminology, colors, typography, interaction states,
and accessibility standards, but use platform-appropriate layouts:

- Windows uses a persistent/collapsible sidebar workspace, contextual top area,
  wide-screen hierarchy, and keyboard-first navigation.
- Android prioritizes frequent tasks, one-handed operation, touch targets,
  software-keyboard behavior, and resilient POS/product/scanner flows.

## Ordered scope

### 0. Durable cross-agent context

Maintain this specification, the detailed implementation roadmap, the stable
live status file, and the concise startup protocol in `AGENT.md`.

### 1. Professional branding and icon

Create multiple distinct icon directions, inspect them at launcher/taskbar size
and on light/dark surfaces, and obtain owner approval before integration. After
approval, replace all relevant Windows, Android adaptive/launcher, docs/favicon,
and Google Play assets. Default Flutter branding must not remain.

### 2. Windows desktop modernization

Audit the current shell before editing. Refine persistent navigation, selection,
top context, responsive density, keyboard focus/order, primary-module routing,
and representative high-frequency screens. Primary destinations keep the shell;
Back is reserved for drill-down flows. Subjective changes require rendered
comparison and owner approval before merge.

### 3. Android mobile modernization

Audit current bottom/overflow navigation and high-frequency workflows. Improve
one-handed reach, touch targets, POS/product/scanner flow, validation, keyboard
interaction, and loading/empty/error/retry states at representative phone sizes.
Subjective changes require rendered comparison and owner approval before merge.

### 4. Accessibility, localization, and public documentation

Use ARB for every changed user-facing string. Verify contrast, text scaling,
semantics, focus, keyboard navigation, touch targets, validation, and recovery
states. Render the published docs at desktop and mobile widths and fix confirmed
overlap, clipping, or overflow. Documentation may not claim unimplemented
behavior.

### 5. Google Play readiness

Prepare repository-side application identity, signing guidance, AAB/versioning
workflow, listing copy/assets, privacy policy, data-safety evidence, permissions,
testing tracks, and release/rollback guidance. Derive declarations from code and
runtime evidence. The owner alone handles identity, payment, OTPs, agreements,
private contact data, signing-key custody, testers, declarations, and publishing.

### 6. Critical correctness

Fix proven data-integrity, migration, backup/restore, authenticated attribution,
stock/POS, receiving, barcode, security, and release blockers encountered during
the roadmap. Do not use this category for speculative cleanup. The receiving
session/localization gap is the first confirmed critical-correctness item. It is
scheduled by the approved priority order unless new evidence raises its severity.

## Non-goals

- Reimplementing behavior already shipped and verified by current evidence.
- A generic AdminLTE clone or a mobile layout stretched across Windows.
- Creating speculative design-system abstractions before two concrete consumers.
- Changing regulated SIPNAP semantics, retention policy, payment integrations,
  server sync, or destructive migrations without owner decisions.
- Committing credentials, identity documents, private addresses, OTPs, payment
  data, signing secrets, or keystores.
- Publishing to Google Play or accepting legal declarations for the owner.

## Acceptance criteria

1. Every agent can identify the latest verified main, active PR, next increment,
   approval gate, and external blocker from repository files plus current GitHub
   state without chat history.
2. Each non-trivial workstream receives a focused child spec and implementation
   plan before code.
3. Each increment uses an isolated branch/worktree, signed commits, complete PR
   description, applicable local gates, all-green required CI, squash merge, and
   green post-merge main CI.
4. Visual work includes rendered alternatives and owner approval before
   implementation or merge, as specified for that increment.
5. Schema changes include migration and data-preservation tests.
6. Platform/device/account claims are reported only with matching evidence;
   unavailable external verification remains explicit.
7. The final release tag is created only after all approved repository work is
   merged and final main Windows/Android builds are green.

## Migration and rollback

This roadmap increment changes documentation only. Future schema-changing child
increments must define forward migration, preservation tests, backup expectations,
and rollback/recovery in their own specs and plans.

## Verification strategy

- Documentation increment: link/path checks, placeholder/contradiction review,
  `git diff --check`, signed-commit verification, and normal repository CI.
- Visual increments: automated widget/accessibility tests plus rendered Windows,
  Android, or browser evidence at named dimensions.
- Operational increments: focused unit/widget/migration tests, full coverage gate,
  relevant platform builds, PR CI, and post-merge main CI.

## Risks and controls

- **Stale roadmap:** update the stable status file after every merge.
- **Duplicate work:** inspect implementation and later PRs before acting on plans.
- **Visual scope explosion:** split work by shell or workflow and require approval.
- **False platform confidence:** label physical-device/account validation explicitly.
- **Cross-agent drift:** keep `AGENT.md` short and route all agents to canonical
  spec, plan, and status files.

## External decisions

- Approval of the final icon and subjective Windows/Android direction.
- Real Google/Play account actions, OAuth consent, identity/payment details,
  signing-key custody, tester selection, declarations, and publication.
- Regulated reporting/retention policy, irreversible data changes, and external
  costs.
