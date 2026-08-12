# AGENT.md — pharmacy-inventory-platform

Source of truth for how to work in this repo. Read this before making changes;
`CLAUDE.md` just points here so any tool (Claude Code, Cowork, opencode, etc.) stays
in sync.

## What this is

Offline-first inventory + POS app for a small pharmacy. Single Flutter codebase,
installable on Windows (desktop) and Android. Full product context:
[`docs/superpowers/specs/2026-07-08-pharmacy-inventory-platform-design.md`](docs/superpowers/specs/2026-07-08-pharmacy-inventory-platform-design.md).
Read specs/plans on demand, not up front — token discipline.

## Mandatory session startup and handoff

Before changing the repository, every agent must:

1. Fetch `origin` and inspect `origin/main`, open PRs, recently merged PRs, and
   current/recent GitHub Actions runs.
2. Read [`docs/superpowers/status/current-roadmap.md`](docs/superpowers/status/current-roadmap.md)
   and the spec/plan linked for the next active increment.
3. Resume an in-flight PR or post-merge main verification before starting
   dependent work. Do not infer completion from stale plan checkboxes.
4. Use implementation, tests, rendered behavior, PR state, and CI as evidence;
   update the live roadmap after every merged increment.

The approved product direction is defined by the
[`cross-agent modernization spec`](docs/superpowers/specs/2026-08-12-cross-agent-modernization-roadmap.md)
and its [`implementation roadmap`](docs/superpowers/plans/2026-08-12-cross-agent-modernization-roadmap.md).
Detailed requirements belong there, not in this file.

## Stack

Flutter (stable) · `drift` (SQLite) · `flutter_riverpod` · ARB-based i18n
(`id` default, `en` toggle) · GitHub Actions CI.

## Code standards

- **Minimal code / YAGNI.** No unrequested abstractions, no interface with one
  implementation, no config for a value that never changes. The smallest diff that
  correctly solves the actual requirement wins. If a stdlib/Flutter/drift feature
  already does it, use that before writing custom code.
- **Layered architecture — respect the boundary:**
  ```
  lib/domain/     pure Dart business logic (entities, use-cases, repository
                  interfaces). No Flutter or drift import here — this is what makes
                  it unit-testable without a database or widget tree.
  lib/data/       drift database, repository implementations, external clients
                  (Google Drive, etc).
  lib/features/   one folder per screen/feature — providers + widgets. Depends on
                  domain, not the other way around.
  lib/core/       shared utilities used by 2+ features. Don't create a file here
                  speculatively — move something in only once a second feature
                  actually needs it.
  ```
- **English everywhere in code**: identifiers, comments, commit messages. UI-facing
  strings go through ARB files (`lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`) — never
  hardcode user-facing text in a widget.
- **Comments** only where the *why* isn't obvious from the code (a workaround, a
  non-obvious constraint, a deliberate simplification). Don't narrate *what* the code
  does — that's what naming is for.
- **Clean/OOP where it earns its keep**: repository pattern at the domain/data
  boundary (see above) because it's what makes business logic testable without a
  real database. Don't reach for a design pattern beyond that unless a second,
  concrete use case needs it.

## Testing

- TDD for new business logic (domain layer): write the failing test first.
- CI enforces **80% line coverage** on `flutter test --coverage`, generated code and
  drift's declarative table DSL are excluded from the gate (see
  `.github/workflows/ci.yml` for the exact exclude patterns and why).
- Widget tests for screens; unit tests for domain logic. Don't write a test for a
  trivial one-line getter.

## Workflow — STRICT & NON-NEGOTIABLE

1. **NEVER push or commit directly to `main`.** All work must be done on a feature branch (e.g. `feat/xxx`, `fix/xxx`, `chore/xxx`).
2. **Every change MUST go through a Pull Request (PR).**
   - Push feature branch to GitHub (`git push origin feat/xxx`)
   - Create PR (`gh pr create`)
   - Wait for ALL GitHub Actions CI checks (`analyze-and-test`, `build-windows`, `build-android`, `secret-scan`, `verify-signatures`) to pass completely (100% GREEN)
   - Merge PR (`gh pr merge --squash`)
3. **No exceptions unless the USER explicitly instructs to bypass in writing.** The AI agent must never decide on its own to push directly to `main` or skip PR/CI validation.
4. **PR titles follow [react-spectrum's naming guide](https://github.com/adobe/react-spectrum/wiki/Pull-Request-Naming-Guide):**
   `type(scope): summary` — e.g. `feat(auth): add login screen and session provider`,
   `fix(pos): correct FEFO batch selection when two batches share an expiry date`.
   Type is one of: `feat`, `fix`, `build`, `chore`, `docs`, `test`, `refactor`, `ci`,
   `localize`, `bump`, `revert`. Scope is optional.
5. **CI must be fully green before merge** (`flutter analyze`, 80%+ coverage tests,
   Windows build, Android build). Watch with `gh run watch`; if red, read the
   exact failing log (`gh run view <run-id> --log-failed`) and fix the specific
   reported error — don't guess broadly.
6. Use `context7` for current library/API docs when unsure — training data may be
   stale, especially for a fast-moving Flutter/drift ecosystem.

## Docs map

- `docs/superpowers/specs/` — design specs (the "what and why").
- `docs/superpowers/plans/` — implementation plans (the "how, task by task").
- Each new feature (POS, backup, notifications, reporting, auth) gets its own spec +
  plan before implementation — see the design spec's "out of scope for this plan"
  notes for what's still pending.
