# AGENT.md — pharmacy-inventory-platform

Source of truth for how to work in this repo. Read this before making changes;
`CLAUDE.md` just points here so any tool (Claude Code, Cowork, opencode, etc.) stays
in sync.

## What this is

Offline-first inventory + POS app for a small pharmacy. Single Flutter codebase,
installable on Windows (desktop) and Android. Full product context:
[`docs/superpowers/specs/2026-07-08-pharmacy-inventory-platform-design.md`](docs/superpowers/specs/2026-07-08-pharmacy-inventory-platform-design.md).
Read specs/plans on demand, not up front — token discipline.

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

## Workflow — non-negotiable

1. **Every change goes through a PR.** No direct commits to `main`.
2. **CI must be fully green before merge** (`flutter analyze`, coverage-gated tests,
   Windows build, Android build). Watch with `gh pr checks --watch`; if red, read the
   exact failing log (`gh run view <run-id> --log-failed`) and fix the specific
   reported error — don't guess broadly.
3. Branch protection on `main` is **not currently enforced** — this repo is private
   on GitHub's free plan, which doesn't support the branch-protection API (403). Rule
   1 and 2 above are enforced by convention, not the server, until the plan changes.
4. Use `context7` for current library/API docs when unsure — training data may be
   stale, especially for a fast-moving Flutter/drift ecosystem.

## Docs map

- `docs/superpowers/specs/` — design specs (the "what and why").
- `docs/superpowers/plans/` — implementation plans (the "how, task by task").
- Each new feature (POS, backup, notifications, reporting, auth) gets its own spec +
  plan before implementation — see the design spec's "out of scope for this plan"
  notes for what's still pending.
