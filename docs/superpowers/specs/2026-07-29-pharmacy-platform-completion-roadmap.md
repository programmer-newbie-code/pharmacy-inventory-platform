# Pharmacy Platform Completion Roadmap

Date: 2026-07-29

## Product promise

One trustworthy offline pharmacy workstation for Windows and Android: staff can
sell, receive, track, restore, audit, and move the business to another device
without specialist knowledge.

## Non-negotiable foundations

- Local database remains authoritative offline.
- All money uses integer rupiah or fixed decimal values; never binary floating
  arithmetic for new financial calculations.
- Every destructive data operation validates first, confirms in UI, is atomic,
  and writes an audit record.
- All production integrations use real credentials or fail visibly; test doubles
  exist only in tests.
- Every screen supports Indonesian and English, keyboard use on Windows, and
  48dp targets on Android.

## Delivery tracks

| Order | Track | Outcome | Release |
|---|---|---|---|
| 0 | Reliability | Complete backups, migrations, test isolation, crash-safe restore | patch |
| 1 | Workflow UX | Role-first dashboard, responsive shell, safe import, accessibility | minor |
| 2 | Inventory | Catalog quality, batches, stock adjustments, suppliers and purchase orders | minor |
| 3 | POS | Fast scanning, payments, receipt/printing, returns, shifts | minor |
| 4 | Compliance | RBAC hardening, audit explorer, controlled-drug workflow, retention | minor |
| 5 | Intelligence | Alerts, reports, export, operational insights | minor |
| 6 | Mobility | Google Drive setup, device transfer, optional multi-device sync | major |
| 7 | Operations | Release quality, privacy, observability, support and recovery playbook | minor |

## Track 0 — Reliability

Implement plan `2026-07-29-backup-integrity-google-drive-hardening.md`.

Additional requirements:

- Drift migrations are versioned and tested from every released schema snapshot.
- Startup checks database integrity and offers a recovery route, never a silent
  reset.
- Backup metadata carries app version, schema version, counts, checksum, and
  creation device ID.
- Restores preserve enough audit provenance to mark imported history.

## Track 1 — Workflow UX

Implement plan `2026-07-29-pharmacy-workflow-ux-modernization.md`.

Primary layout: desktop navigation rail + workspace; Android bottom navigation
for POS, inventory, alerts, and more. Every role sees a different primary action.

## Track 2 — Inventory and purchasing

- Product form uses lookup to autofill non-commercial medicine data; barcode,
  price, supplier, batch, expiry, and quantity remain explicit staff input.
- Stock adjustments require reason, quantity delta, actor, timestamp, and audit
  record. Negative stock is rejected.
- Receiving a PO creates batches in one transaction and shows discrepancy
  between ordered and received quantities.
- Supplier records include contact, terms, lead time, active status, and history.
- Reorder recommendations use threshold, supplier lead time, open PO quantity,
  and average daily sales; recommendations remain editable.

## Track 3 — POS and cashier operations

- Scan/search input has focus on screen open; supports camera and keyboard-wedge
  scanners; not-found barcode offers add-product or retry action.
- Cart supports quantity edit, remove, controlled-drug confirmation, price-below-
  cost reason, discount authorization, and payment method.
- Cashier must open a shift before payment; close-shift shows expected cash,
  counted cash, discrepancy, reason, and supervisor review.
- Receipts support preview, printer selection on Windows, Android share/save, and
  stable receipt numbers. Failed printing never rolls back a completed sale.
- Returns select original receipt/item, enforce returnable quantity, restock the
  correct batch where possible, and write linked audit records.

## Track 4 — Compliance and security

- Session inactivity timeout and re-authentication for admin actions.
- Password policy, change/reset audit, no plaintext secrets in source or logs.
- Controlled drugs require prescription metadata and show regulatory category in
  product, cart, receipt, report, and audit views.
- Audit explorer filters by actor, action, record, date, and module; export is
  administrator/auditor only.
- Privacy screen documents local data, Google Drive access, retention, and how
  to erase a device safely.

## Track 5 — Alerts and reporting

- Alert inbox prioritizes expired, expiring, low stock, failed backup, and open
  shift warnings. Each alert has an action and dismiss/snooze policy.
- Reports use a date range, location/category/supplier filters, export progress,
  and empty-state explanation.
- Financial reports show gross revenue, refunds, COGS, gross margin, discounts,
  and cash discrepancy separately.
- Exports include deterministic filenames and an audit event.

## Track 6 — Mobility and integration

- Google OAuth is configured per Android package/signing key and documented for
  Windows. Drive permissions limited to app-created files.
- Device transfer uses verified backup, restore preview, post-restore health
  check, and a printed/on-screen handover checklist.
- Multi-device sync is optional phase 2 only. It requires server-side identity,
  sync protocol, idempotent operations, conflict policy, encryption, and a
  migration from single-active-device mode. It must not ship as partial file
  copying.
- BPOM data integration has source attribution, cached freshness date, timeout,
  offline fallback, and a maintenance owner.

## Track 7 — Release and support operations

- CI includes analyze, tests/coverage, Windows, Android, generated-file check,
  dependency audit, and secret scan.
- Releases require version bump PR, changelog, signed tag, artifacts, smoke test,
  and rollback note.
- Crash/error reports contain no patient, prescription, access-token, or raw
  database data.
- User guide has first setup, backup/restore, scanner, receipt printer, data
  import, role management, and troubleshooting sections.

## Deferred decisions

These require an explicit owner decision before implementation: payment gateway,
multi-branch pricing/tax, cloud sync provider, prescription image retention,
regulatory reporting jurisdiction, and electronic receipt legal requirements.
