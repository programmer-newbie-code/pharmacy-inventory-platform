# Design Spec: Multi-Device LAN Synchronization Engine

**Goal:** Enable multiple cashier registers in the same pharmacy location to synchronize stock adjustments, POS sales, and inventory changes in real-time over the Local Area Network (LAN) without requiring cloud servers or internet connection.

---

## 1. Architecture & Topologies

- **Primary / Secondary Architecture**:
  - One desktop terminal operates as the **Primary Sync Host** (hosting a lightweight WebSocket + HTTP REST server on port 8443).
  - Secondary cashiers (Windows/Android) connect automatically via mDNS / Zeroconf network discovery (`_pharmacy-sync._tcp.local`).

- **Data Protocol & Conflict Resolution**:
  - Event Sourcing with Vector Clocks / Conflict-free Replicated Data Types (CRDTs).
  - Inventory decrements are applied transactionally. If two cashiers sell the last box of a batch simultaneously, the Primary Host validates stock remaining before committing and returns a stock conflict exception to the secondary cashier.

---

## 2. Security & Encryption

- **mTLS & Shared Pre-Key**:
  - Initial pairing between devices uses a QR code or 6-digit PIN exchange on the local network.
  - All LAN socket traffic is encrypted using AES-256-GCM with TLS 1.3 certificates self-signed by the Primary Host.

---

## 3. Fallback & Offline Resilience

- **Store-and-Forward Offline Queue**:
  - If network connectivity drops between cashiers, sales are queued in the local `drift` database under `pending_sync_queue`.
  - When connection is restored, the queue is replayed in chronological order with server-side validation.
