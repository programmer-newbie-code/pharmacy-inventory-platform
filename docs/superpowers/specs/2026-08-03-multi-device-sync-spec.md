# Multi-Device Sync Specification for Pharmacy Inventory Platform

> **Approved Architecture Spec**
> **Date:** 2026-08-03
> **Status:** Draft / Approved for future multi-device synchronization engine implementation.

---

## 1. Executive Summary
This document specifies the technical architecture for real-time and asynchronous multi-device data synchronization across Windows and Android devices running the Pharmacy Inventory Platform. 

Sync operations remain strictly decoupled from core local POS and inventory operations: local SQLite/Drift operations commit immediately to ensure 0ms latency at the counter, while sync operates asynchronously in the background.

---

## 2. Authentication & Authorization (Auth)
- **Identity Provider**: Google OAuth 2.0 / OpenID Connect (OIDC).
- **Access Tokens**: Short-lived JWTs (1 hour expiration) stored securely in platform keychain (`flutter_secure_storage` / Windows Credential Manager).
- **Refresh Tokens**: Stored encrypted; automatically used to refresh access tokens without user interaction.
- **Tenant Scope**: Each sync payload includes an authenticated `organization_id` and `pharmacy_id` verified by the backend API. Device authorization requires explicit Admin approval from the primary device.

---

## 3. Operation Log Architecture
- **Local Sync Log Table**: `sync_operation_log`
  - `id`: Auto-incrementing local ID.
  - `operation_id`: UUIDv4 generated at mutation time.
  - `table_name`: Target entity (e.g., `products`, `sale_transactions`, `stock_batches`).
  - `action`: `INSERT`, `UPDATE`, or `DELETE`.
  - `payload_json`: Delta state of modified record.
  - `timestamp`: UTC microsecond timestamp.
  - `status`: `pending`, `syncing`, `synced`, `conflict`.

---

## 4. Conflict Resolution Matrix

| Entity | Conflict Scenario | Resolution Strategy | Rationale |
| :--- | :--- | :--- | :--- |
| **Sale Transactions** | Duplicate transaction ID across offline cashiers | Immutable UUID | Transactions are append-only; UUID ensures zero collision |
| **Stock Batches** | Simultaneous deduction on 2 POS terminals | Vector Clock + FEFO Allocation | Server recalculates remaining base units against global batch queue |
| **Product Metadata** | Simultaneous price edit by 2 admins | Last-Write-Wins (LWW) via UTC timestamp | Highest UTC timestamp wins; Audit log records both versions |
| **Cashier Shifts** | Discrepancy on close shift across terminals | Separate Shift Records per Terminal ID | Shifts are terminal-bound; aggregated in reporting |

---

## 5. Encryption & Data Protection
- **In-Transit**: TLS 1.3 enforced for all client-to-server sync endpoints.
- **At-Rest (Cloud)**: AES-256 field-level encryption for sensitive patient data (patient names, prescription metadata).
- **Client Encryption Key**: Managed via hardware-backed Keystore/Keyring (`Android KeyStore`, `Windows DPAPI`).

---

## 6. Idempotency & Replay Protection
- Every client HTTP request carries an `X-Idempotency-Key: <operation_id>` header.
- The server maintains a Redis/Spanner idempotency cache (24-hour TTL).
- Duplicate requests return the original response without re-executing business logic or state mutations.

---

## 7. Offline Queue Management
- **Persistence**: Pending operations are written to SQLite `sync_operation_log` synchronously within the same database transaction as the business mutation.
- **Retry Mechanism**: Exponential backoff with jitter (initial retry 2s, max backoff 5 minutes).
- **Network Awareness**: Listens to connectivity changes (`connectivity_plus`); auto-flushes queue upon network restoration.

---

## 8. Database Migration & Schema Compatibility
- Payloads carry a `schema_version` integer matching `AppDatabase.schemaVersion`.
- Server handles backwards-compatible payload transformations for N-1 client versions.
- If a client encounters a server payload with `schema_version > local_version`, sync pauses for that table and prompts user to update the app.

---

## 9. Infrastructure Cost Model
- **Target Backend**: Serverless (Cloud Run + Spanner / Cloud SQL Postgres).
- **Estimated Payload Size**: ~500 bytes per transaction.
- **Cost Projection**:
  - 100 sales/day per pharmacy = ~50 KB/day sync traffic.
  - Compute cost per pharmacy/month: < $0.05 USD under standard GCP free tier.

---

## 10. Privacy & Compliance
- Compliance with BPOM / Kemenkes data retention policies.
- PII (Patient Identifiable Information) on prescription sales is encrypted prior to transmission.
- Admin can trigger **Remote Wipe** signal to purge local database on lost/stolen mobile terminals.

---

## 11. Rollback & Recovery Strategy
- **Client-Side Snapshot**: Before applying a cloud sync batch, a local SQLite savepoint (`SAVEPOINT sync_apply`) is created.
- **Transaction Rollback**: If applying a batch fails mid-process, `ROLLBACK TO sync_apply` is executed, keeping local state uncorrupted.
- **Corrupt State Recovery**: Admin can initiate **Force Resync**, which downloads a fresh full state snapshot from cloud storage.
