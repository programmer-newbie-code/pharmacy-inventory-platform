# Backup Safety and Workflow UX — Design

Date: 2026-07-29

## Goal

Make the pharmacy app safe to trust with real business data and easy to operate
for staff who are not technical users. Work is split into two independently
shippable projects:

1. Backup integrity and Google Drive hardening.
2. Workflow-focused UX/UI modernization.

## 1. Backup Integrity and Google Drive Hardening

### Problems

- Production code contains `isMock` and `test_token` paths.
- JSON backup omits `auditLogs`, `backupLogs`, `cashierShifts`, `suppliers`,
  `purchaseOrders`, and `purchaseOrderItems`.
- Restore deletes live data before fully validating backup structure.
- Restore accepts a manually typed path instead of a platform file picker.
- Google Drive account state and last successful upload are not clear in UI.
- Raw exceptions and HTTP bodies can reach users.

### Required behavior

- Production services contain no mock/test branches. Tests use injected fakes.
- Backup format has a schema version, creation timestamp, record counts, and all
  business tables.
- Restore validates format, supported version, required collections, and
  foreign-key references before changing live data.
- Restore remains atomic: validation failure changes nothing; database write
  failure rolls the transaction back.
- User previews backup date, version, and record counts before confirmation.
- Local restore uses a native file picker on Windows and Android.
- Drive UI shows disconnected, connected, uploading, success, and failure states.
- User-facing errors explain the next action without tokens, stack traces, or raw
  response bodies.

### Backup envelope

```json
{
  "schemaVersion": 2,
  "createdAt": "2026-07-29T12:00:00.000Z",
  "appVersion": "1.2.1",
  "counts": {
    "users": 2,
    "products": 150,
    "stockBatches": 240
  },
  "data": {
    "users": [],
    "storageLocations": [],
    "products": [],
    "stockBatches": [],
    "saleTransactions": [],
    "saleItems": [],
    "auditLogs": [],
    "backupLogs": [],
    "cashierShifts": [],
    "suppliers": [],
    "purchaseOrders": [],
    "purchaseOrderItems": []
  }
}
```

Version 1 backups remain importable through a small normalization step. New
exports always use version 2.

### Test isolation

`GoogleDriveBackupService` receives two collaborators:

- account authorization provider;
- Drive upload client.

Production providers use Google implementations. Tests inject deterministic
fakes. No magic token can convert a production upload into a reported success.

### Acceptance criteria

- Round-trip test covers every business table.
- Invalid, unsupported, and referentially broken backups leave existing data
  untouched.
- Tests cannot call a production-only mock flag because none exists.
- Android and Windows builds pass.
- Backup screen has no typed file-path field.
- All new UI strings exist in Indonesian and English ARB files.

## 2. Workflow-Focused UX/UI Modernization

### Users and jobs

- Cashier: open shift, scan items, accept payment, handle returns.
- Inventory staff: receive stock, find products, handle low/expiring stock,
  import catalog data.
- Admin: oversee business, users, backup, reports, and settings.
- Auditor: inspect reports and trace activity without edit controls.

### Design direction

The visual identity is “clinical calm”: deep teal, clean white surfaces, warm
neutral background, and Indonesian medicine-category colors only where they
carry regulatory meaning. The memorable element is a persistent operational
status strip showing shift, backup, low stock, and expiry health.

Feature cards stop using unrelated rainbow colors. Teal marks primary action;
green, amber, and red communicate state; blue supports informational content.

### Navigation

Dashboard content is ordered by work urgency:

1. Primary action for the current role.
2. Operational status strip.
3. Items requiring attention.
4. Secondary modules.

Desktop uses a compact navigation rail and content workspace. Android uses
bottom navigation for the highest-frequency destinations plus a “More” screen.
Restricted destinations are hidden when they are irrelevant, not displayed as
disabled mystery cards.

### Key flows

#### Cashier

Open shift → scan/search → review cart → payment → receipt → next sale.

#### Inventory

Attention list → select product/batch → receive or correct stock → confirmation.

#### CSV import

Choose file → validate columns → preview rows → resolve duplicates → import →
show counts and downloadable error report.

Bundled Indonesian drug data remains a lookup catalog. It is not silently
inserted as sellable inventory because it has no real barcode, purchase price,
stock quantity, supplier, or expiry.

### Accessibility and language

- Minimum 48dp interactive targets.
- Keyboard traversal and visible focus on Windows.
- Text and icon together for important actions.
- Body text minimum 14sp; critical numbers minimum 20sp.
- Status never relies on color alone.
- Reduced-motion preference respected.
- Every user-facing string localized through ARB.
- Currency and dates use Indonesian locale formatting.

### Acceptance criteria

- Role-specific primary task reachable in one action from dashboard.
- No sample inventory is prefilled in CSV import.
- Search updates without requiring Enter and has an explicit empty state.
- Destructive actions show consequences and require confirmation.
- Loading, empty, success, partial-success, and failure states give a next step.
- Widget tests cover phone and desktop widths plus keyboard focus for primary
  workflows.

## Delivery order

1. Backup safety first because current backups can omit business data.
2. Workflow UX second, beginning with shared design tokens and dashboard.
3. Inventory import and backup UI use the same file-selection and result-state
   patterns.

Each project uses its own feature branch, PR, green CI cycle, merge, main build,
and release tag according to `AGENT.md`.
