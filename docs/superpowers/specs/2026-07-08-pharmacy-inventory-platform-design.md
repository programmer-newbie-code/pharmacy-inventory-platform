# Pharmacy Inventory & POS Platform — Design (v1 / MVP)

Date: 2026-07-08
Repo: `programmer-newbie-code/pharmacy-inventory-platform` (private)

## 1. Problem & Goal

Small pharmacy ("apotik") needs one app to replace manual stock/expiry tracking and
manual sales recording. Must run as an installable Windows desktop app AND a normal
Android app, from one codebase, working offline with local storage and automatic
cloud + local backup.

Out of scope for v1 (explicitly deferred):
- Two devices writing at the same time (realtime multi-device sync)
- Notifications while the app is closed (background service)
- Multi-branch / multi-store
- Online payment gateway integration

## 2. Stack & Architecture

- **Flutter** (Dart), single codebase → Windows (`.exe` + installer via Inno Setup/MSIX)
  and Android (APK/AAB).
- **drift** — SQLite ORM + type-safe migrations.
- **riverpod** — state management.
- **mobile_scanner** — camera-based barcode scanning (Android camera / Windows webcam).
  USB/Bluetooth handheld scanners need no library — they emit keyboard input, captured
  by a focused input listener.
- **Google Drive API** (OAuth2) — cloud backup destination.
- **flutter_localizations** + ARB files — UI strings in `en`/`id`. All code identifiers,
  comments, and commit messages are in English regardless of UI locale.

### Layout

```
lib/
  domain/     # entities, repository interfaces, use-cases — pure Dart, no Flutter/drift import
  data/       # drift tables/DAOs, repository implementations, Google Drive client
  features/   # presentation: inventory/, pos/, auth/, reports/, backup/, notifications/
  core/       # unit-conversion util, permission checker, DI setup
```

Domain layer has no dependency on `data`, so business rules (unit conversion, pricing,
FEFO selection, permission checks) are unit-testable without a database.

### Single-active-device model

Only one device is authoritative at a time (either the Windows PC or one Android
tablet/phone). Moving to a different device = restore the latest backup on it. This
also covers the "might switch to a tablet later" requirement without needing a sync
engine. `updated_at` and `device_id` columns are included on core tables now so a
future multi-device sync engine (phase 2) doesn't require a schema rewrite.

## 3. Data Model

```
users
  id, username, password_hash, role (admin|inventory|kasir|audit), created_at

storage_locations
  id, code, name, description?, created_at

products
  id, barcode, internal_code, name, active_ingredient, ingredient_pct,
  base_unit            -- smallest sellable unit, e.g. "tablet"/"butir"
  purchase_unit        -- unit goods arrive in, e.g. "strip"/"box"
  units_per_purchase_unit  -- conversion factor, e.g. 1 strip = 10 tablet
  cost_price_per_base_unit, margin_pct
  reorder_threshold    -- base_unit qty; low-stock alert fires at/below this
  is_controlled        -- true = "obat keras"/daftar G, requires prescription
  storage_location_id (FK, nullable)
  category
  created_by, updated_by, created_at, updated_at, device_id

stock_batches
  id, product_id (FK), batch_no, received_date, expiry_date,
  qty_received, qty_remaining   -- both in base_unit
  cost_price_per_base_unit, supplier
  created_by, created_at, updated_at, device_id

sale_transactions
  id, txn_no, patient_name?, cashier_id (FK users), total_amount, payment_method,
  has_prescription (bool), prescription_photo_path (nullable), doctor_name (nullable),
  created_at, device_id

sale_items
  id, transaction_id (FK), product_id (FK), batch_id (FK), qty_sold (base_unit),
  unit_price, subtotal

audit_log
  id, table_name, record_id, action (create|update|delete),
  old_value (json), new_value (json), user_id, timestamp
  -- append-only, never updated/deleted

backup_log
  id, timestamp, destination (drive|local), status, file_size
```

All stock math (deduction, remaining, min-price) operates only in `base_unit`.
Conversion from `purchase_unit` happens once, at the moment a batch is recorded.

### Why expiry tracking is per-batch, not per-product

The same product received on different dates has different expiry dates and
different remaining quantities. `stock_batches` is one row per delivery, so "Product A
received today" and "Product A received next week" are two independent rows, each
with its own `expiry_date`/`qty_remaining`. Expiry and low-stock views always list
batches, not aggregated products, so a pharmacist can see exactly which delivery is
expiring and how many units of it remain.

### Storage location management

`storage_locations` is its own table (not a free-text field) so locations can be
listed, renamed, and browsed ("what's in Rak A3?") without relying on consistent
free-text entry. A product has one location; changing it is a normal product edit.

### Controlled drugs / prescription

`products.is_controlled` flags drugs requiring a doctor's prescription ("obat keras" /
daftar G). When a sale transaction includes at least one controlled product, the POS
screen offers (does not require) attaching a prescription photo and doctor name —
matching real practice where a resident doctor sometimes prescribes on the spot and a
paper prescription doesn't always exist.

## 4. Pricing

`min_sell_price = cost_price_per_base_unit * (1 + margin_pct)`. The POS screen warns
(non-blocking) if a cashier enters a price below this so a sale below cost is a
deliberate choice, not an accident.

## 5. Roles & Permissions

| Role      | Products/Batches | Storage locations | Sales (POS) | Reports | Audit log | Users |
|-----------|-------------------|--------------------|-------------|---------|-----------|-------|
| admin     | full              | full               | full        | full    | view      | full  |
| inventory | full*             | full               | view        | view    | -         | -     |
| kasir     | view              | view               | create      | own txns| -         | -     |
| audit     | view              | view               | view        | full    | view      | -     |

`*` Inventory role can edit a batch only while `qty_remaining == qty_received` (nothing
sold from it yet). Once any unit has been sold, editing that batch's cost/expiry
requires the `admin` role — this is the specific guard against manipulating stock
records after the fact. Every create/update/delete on `products`, `stock_batches`, and
`sale_transactions` writes an `audit_log` row (old/new value, user, timestamp),
regardless of role — this is what the `audit` role reviews.

## 6. Notifications (in-app only, v1)

Checked once per app open (no background service, matches daily-use pattern):
- **Expiring batches**: `stock_batches` where `expiry_date <= today + N days` and
  `qty_remaining > 0`, listed per batch (product, batch_no, expiry_date, qty_remaining).
  `N` is a configurable threshold (default 30 days).
- **Low stock**: products where sum of `qty_remaining` across batches <= a per-product
  reorder threshold.

Shown as an in-app badge/list on open; no OS-level push in v1.

## 7. Backup & Restore

- Triggered once per day on app open ("already backed up today?" check).
- Exports the SQLite database file, then: copies it to a local folder AND uploads to
  Google Drive (OAuth2, refresh token stored locally).
- Every attempt logs a `backup_log` row (destination, status, size) so failures are
  visible in-app, not silent.
- Restore: pick a backup file (local or Drive) → overwrites the local database. This
  is also the mechanism for moving to a different device (Windows ⇄ tablet/phone).

## 8. Reporting

Monthly financial export to Excel (`.xlsx`): transactions, revenue, cost of goods sold
(from batch cost price at time of sale), margin. Exact column layout is an
implementation detail, not fixed here.

## 9. Testing & CI

- Unit tests: unit-conversion, min-price calculation, FEFO batch selection, permission
  matrix, backup file integrity.
- Widget tests: POS screen, inventory list, expiry alert list.
- GitHub Actions on every PR: `flutter analyze` → `flutter test --coverage` → fail the
  check if line coverage < 80% (via `lcov`) → `flutter build windows` and
  `flutter build apk` as a build-health check.
- Branch protection on `main`: PRs require all checks green before merge.

## 10. Assumptions

- Currency: IDR, no multi-currency.
- Single store/branch in v1.
- Internet is available at least daily (for the backup upload); the app itself is
  fully offline-capable otherwise.
