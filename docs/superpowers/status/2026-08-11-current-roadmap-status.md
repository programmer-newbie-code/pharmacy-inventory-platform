# Pharmacy Platform Current Roadmap Status

**Audit date:** 2026-08-11
**Audited revision:** `2e07424` (`fix(scanner): stop camera when app backgrounds (#133)`)
**Method:** implementation and test evidence in the current main branch, open-PR state, and current CI configuration. Historical plan checkboxes are not treated as completion evidence.

## Status vocabulary

- **Shipped:** implementation and automated coverage exist on main. It still requires normal release smoke testing.
- **Partial:** a usable implementation exists, but an approved acceptance criterion is missing or lacks sufficient verification.
- **Missing:** no implementation evidence was found.
- **Deferred:** intentionally requires a separate approved product or external-authority decision.
- **Superseded:** an older plan is replaced by a later shipped implementation; retain it only as history.

## Delivery baseline

| Area | Status | Evidence | Remaining work |
| --- | --- | --- | --- |
| Branch, signed-commit, PR, CI workflow | Shipped | `AGENT.md`, `.github/workflows/ci.yml`, and PR #133: analyzer, coverage, Windows, Android, signatures, and secret scan all passed before merge; main run `31516784102` passed for `2e07424`. | Keep enforcing the workflow for every increment. |
| Release automation | Partial | CI builds Windows and Android artifacts and creates releases from signed `v*` tags. | Verify the next release tag only after all remaining roadmap increments land; keep a release smoke/rollback record. |
| Current best-selling export increment | Shipped | PR #130 added `ExcelReportService.generateBestSellingMedicinesReport`/`exportAndSaveBestSellingMedicinesReport`, `ReportRepository.exportBestSellingMedicines` (audit-logged), an accessible export button on `SalesAnalyticsScreen`, and wired `reportRepositoryProvider` to actually inject `AuditLogger` (previously a no-op gap — see `docs/superpowers/specs/2026-08-11-best-selling-medicines-export.md`). | None outstanding for this increment; export/audit parity with other reports achieved. |

| Current report-export audit status | Shipped for best-selling, procurement, and cash movement | PR #130 added best-selling Excel export/audit. PR #132 added filtered, deterministic procurement and cash-movement Excel exports, UI feedback, and save-before-audit records. This supersedes the earlier best-selling-only delivery row. | Audit the classic sales export, SIPNAP export, and prescription CSV paths separately; do not infer their parity from these increments. |
| Scanner lifecycle increment | Shipped in code | PR #133 groups `hidden`, `paused`, and `inactive` lifecycle states with `controller.stop()` and resumes only on `resumed`; focused scanner tests and all CI build/test gates passed before merge. | Physical Android camera and Windows keyboard-wedge smoke tests remain required. |

## Approved product workstreams

| Workstream / approved item | Status | Current implementation evidence | Verified gap or next action |
| --- | --- | --- | --- |
| Offline-first Drift database, role/session foundation | Shipped | `lib/data/database.dart`, `lib/features/auth/`, role tests, migration tests. | Continue migration fixtures whenever schemas change. |
| Inventory, batches, adjustments, suppliers, purchase receiving | Partial | Repositories and screens exist for products, batches, suppliers, purchase orders, stock adjustments, and receiving; workflow tests exist. | Audit the remaining acceptance rules in the completion roadmap: negative-stock protection, full receiving reconciliation, and reorder formula fixture coverage. |
| POS, returns, shifts, receipts, printer recovery | Partial | POS, return, shift, receipt PDF/storage, and targeted tests are present. | Verify price-below-cost authorization, printer-failure recovery, and close-shift supervisor review against their approved acceptance tests. |
| Backup integrity and restore | Partial | `backup_service.dart`, backup UI/tests, restore preview, backup document validation, and database-health service exist. | Execute the backup-hardening plan against actual data fixtures: checksum/version/device metadata, atomic failure recovery, migration coverage, and real-device restore smoke test. |
| Google Drive backup and desktop OAuth | Partial / external verification required | Desktop OAuth configuration, credential store, upload client, and tests exist; Windows now displays configuration guidance instead of a plugin exception. | Verify real Android and Windows OAuth with an authorized Google Cloud configuration and account; remove any remaining misleading success history if found. This needs external OAuth authority. |
| Android camera barcode scanning | Partial | `camera_scanner_dialog.dart`, Android camera-permission test, retryable permission state, scanner UI, and PR #133 lifecycle stop behavior exist. | Physical-device scan, permission denial/retry, cancellation, torch, lookup, duplicate suppression, and lifecycle smoke testing remain unproven. |
| Windows keyboard-wedge barcode scanning | Shipped in code / physical verification pending | POS and add-product tests assert desktop scanner-field behavior and Windows guidance; PR #133 makes shared scanner lifecycle shutdown explicit. | Smoke-test USB/Bluetooth scanners for focus, Enter/tab completion, duplicates, and not-found recovery. |
| Indonesian drug catalog, lookup, CSV import, history | Partial | Bundled `assets/data/indonesian_drugs.csv`, lookup/updater services, staged import dialog, provenance docs, and import-history tests exist. | Verify catalog freshness/attribution, downloaded-catalog fallback, large-file progress, conflict policy, and atomic rollback with production-sized fixtures. |
| Desktop dashboard workspace | Shipped in code / UX review pending | Responsive shell, desktop sidebar, breadcrumb, role-first home, and accessibility tests exist. | Conduct visual/keyboard QA on a real Windows build; retain subjective design changes for product review. |
| Android navigation and mobile usability | Partial | Responsive shell and bottom navigation are implemented and tested, including the More overflow sheet. | Revisit task frequency, one-handed use, POS/scanner flow, and real-device text scaling; decide whether navigation changes are warranted from evidence. |
| Accessibility and localization | Partial | ARB files, semantic/key tests, responsive/accessibility workflow tests, and formatters exist. | Audit remaining hard-coded operational strings, screen-reader labels, focus traversal, contrast, and text-scale behavior feature-by-feature. |
| Reports, financial exports, alerts | Shipped for best-selling; Partial overall | Sales summary, procurement, cash movement, SIPNAP, and best-selling export services exist with audit logging; `SalesAnalyticsScreen` has Today/Week/Month/custom presets, ranking modes, and export. | Other reports (procurement, cash movement) still lack the same export/audit parity check performed for best-selling in this increment — worth a follow-up audit pass. |
| Patients, prescriptions, controlled drugs, compounding | Partial | Patient, prescription, SIPNAP, and compounding modules/tests exist. | Verify controlled-drug end-to-end policy enforcement and document the regulatory-retention decision before altering records or attachment deletion. |
| Privacy and local-data transparency | Shipped in code | Privacy spec/screen and ARB strings document local storage and optional Drive. | Revalidate after any sync, telemetry, or retention change. |
| GitHub Pages/docs-site responsive gallery | Partial | Docs-site responsive-image/layout plans and deployed `deploy-gh-pages` job exist. | Render and inspect the published page at desktop and mobile widths; fix only confirmed overlap/overflow. |
| App icon and repository discovery | Partial | App-icon worktree/branch exists in local history; README and docs exist. | Verify icon assets are present on current main and configure GitHub About/topics if still absent. |
| Multi-device/LAN/cloud sync | Deferred | Separate specs exist (`2026-08-03-multi-device-sync-spec.md`, `2026-08-07-multi-device-lan-sync.md`). | Do not implement partial file-copy sync. Requires an approved server, identity, encryption, conflict, cost, privacy, and rollback decision. |
| Payment gateway, multi-branch pricing/tax, electronic-receipt law | Deferred | Explicit deferred decisions in `2026-07-29-pharmacy-platform-completion-roadmap.md`. | Requires product/legal/financial owner decision. |

## Immediate ordered backlog

1. Audit the classic sales export's missing audit record, then separately assess SIPNAP and prescription CSV paths; create a spec/plan only for proven gaps.
2. Perform evidence-led Google Drive/backup and barcode audits. Implement reproducible code defects; request OAuth or physical-device access only where verification cannot be reproduced.
3. Audit each remaining partial workflow against explicit acceptance criteria and create a separate spec/plan per independent gap.
4. Complete visual QA of Windows, Android, and GitHub Pages using published/release builds; keep subjective redesigns for user review.
5. After every green merged increment, repeat this status document with evidence and retire superseded backlog entries.

## Process note

Starting with this increment, every new feature/fix gets a spec
(`docs/superpowers/specs/`) and a bite-sized implementation plan
(`docs/superpowers/plans/`) written *before* implementation, not just for
large features. See `2026-08-11-best-selling-medicines-export.md` for the
first spec+plan pair written this way (retroactively, after two avoidable
CI fix-forward cycles motivated the change).

## Explicitly deferred decisions

- Real Google Cloud OAuth credentials/account consent and production verification.
- Prescription/photo retention and automatic media deletion policy.
- Payment integration, multi-branch tax/pricing, and electronic-receipt legal requirements.
- Server-backed multi-device synchronization design, hosting cost, identity, encryption, and conflict policy.
