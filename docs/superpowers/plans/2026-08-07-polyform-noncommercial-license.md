# Implementation Plan: PolyForm Noncommercial License 1.0.0 & CI Hardening

> **Goal:** Transition repository license to PolyForm Noncommercial 1.0.0 and harden CI workflow dependencies.

---

## Tasks

- [x] Create feature branch `feat/noncommercial-license-ci-hardening`.
- [x] Update `LICENSE` with PolyForm Noncommercial 1.0.0 and explicit preamble clauses.
- [x] Update `README.md` to detail operational rights vs commercial prohibition.
- [x] Update `docs/release/RELEASE_CHECKLIST.md` to reflect PolyForm Noncommercial licensing rules.
- [x] Add future capabilities design specs (`docs/superpowers/specs/2026-08-07-multi-device-lan-sync.md` and `docs/superpowers/specs/2026-08-07-controlled-drug-prescription-attachments.md`).
- [ ] Run local pre-flight checks (`flutter analyze`, `flutter test --coverage`, `build_runner`).
- [ ] Commit and push feature branch to origin.
- [ ] Create Pull Request (`gh pr create`).
- [ ] Verify 100% green CI build across all 5 workflow jobs.
- [ ] Merge PR via squash (`gh pr merge --squash`).
