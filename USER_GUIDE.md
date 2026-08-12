# 📖 PharmaLoka — User Guide & Manual

Welcome to **PharmaLoka**! This application is an offline-first inventory management and Point-of-Sale (POS) counter system designed specifically for pharmacies, clinics, and drugstores.

---

## 🎯 Quick Start Guide

### 1. First-Time Admin Setup
When launching the platform for the first time, you will be prompted to create the initial **Administrator Account**:
1. Enter your full name, username, and a strong password.
2. The system automatically initializes the SQLite database with role-based permissions (`Admin`, `Pharmacist`, `Cashier`).

---

## 🛒 2. POS Sales Counter & FEFO Stock Deduction
Navigate to **POS Sales Counter** from the main dashboard:
- **Product Search & Barcode Scanning**: Type the medicine name or scan the barcode using a USB/Bluetooth scanner into the search bar.
- **Cart Management**: Click `+` to add items to the cart. Quantities and totals update dynamically.
- **Controlled Drugs (`isControlled`)**:
  - If a prescription drug is added to the cart, the system enforces **Prescription Verification**.
  - Enter the **Doctor Name**, **Patient Name**, and check the **Prescription Verified** box.
- **First-Expired, First-Out (FEFO)**:
  - When completing checkout, stock is automatically deducted from the **earliest expiring stock batch** first.
- **Minimum Sell Price Safeguard**:
  - The system warns you if a selling price is set below the base unit cost price.
- **Digital Receipt**: Click **Complete Sale (Checkout)** to view and print the transaction summary receipt.

---

## 📦 3. Inventory Catalog & FEFO Stock Entry
Navigate to **Inventory Catalog**:
- **Add New Product**:
  - Enter product name, barcode, internal code, active ingredient, storage location, unit conversion specs (e.g., 1 Box = 100 Tablets), cost price, and margin percentage.
- **Receive Stock Batch**:
  - Click **Receive Stock Batch** on any product.
  - Enter batch number, supplier name, quantity received in purchase units, cost price, and **Expiry Date**.

---

## ⚠️ 4. Expiry & Low-Stock Alerts Dashboard
Navigate to **Expiry & Low Stock Alerts**:
- **Expiring Batches Tab**:
  - View batches expiring within **30, 60, 90, or 180 days**.
  - Batches expiring within 30 days are highlighted in **RED** badge; 90 days in **ORANGE**.
- **Low Stock Products Tab**:
  - Displays products whose remaining stock is at or below their configured **Reorder Threshold**.

---

## 💾 5. Database Backup & BPOM Compliance Export
- **Prescription Sales CSV Export**:
  - Export structured CSV compliance logs of controlled drug transactions for BPOM / Kemenkes reporting.
- **Database Backup**:
  - Export database records to local JSON files (`pharmacy_backup_<timestamp>.json`). All backup operations are recorded in the `BackupLogs` audit trail.

---

---

## ☁️ 6. Google Cloud OAuth & Google Drive Backup Configuration

To enable cloud backup and restore to Google Drive:

### 1. Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/) and create a project (e.g., `pharmacy-inventory-platform`).
2. Navigate to **APIs & Services > Library** and enable **Google Drive API**.
3. Configure the **OAuth Consent Screen**:
   - User Type: External or Internal (depending on organization setup).
   - Scopes: Add `https://www.googleapis.com/auth/drive.appdata` (Application Data folder) and `https://www.googleapis.com/auth/drive.file`.

### 2. Android Client Credentials
1. In **APIs & Services > Credentials**, click **Create Credentials > OAuth client ID**.
2. Select Application Type: **Android**.
3. Package Name: `com.programmernewbiecode.pharmacy_inventory_platform`.
4. SHA-1 Fingerprint:
   - For debug builds: Get via `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey`.
   - For release builds: Get SHA-1 and SHA-256 fingerprints from your release keystore or Play Console App Signing.

### 3. Windows Desktop Client Credentials
1. Create OAuth client ID with type **Desktop Application**.
2. Set Authorized Redirect URI: `http://localhost:8080` (or loopback IP redirect).
3. Save `client_id` and `client_secret` into app configuration.

---

## 📲 7. Verified Device-to-Device Transfer Checklist

When migrating pharmacy data to a new Windows or Android device:

- [ ] **Step 1: Perform Final Backup on Old Device**
  - Open **Database Backup** screen.
  - Perform a **Local Backup** (`pharmacy_backup_<timestamp>.json`) AND trigger a **Google Drive Sync**.
  - Verify that the backup status indicates `SUCCESS` with a valid timestamp and checksum.

- [ ] **Step 2: Verify Backup Integrity**
  - Check `BackupLogs` audit trail on old device to verify no data corruption occurred.
  - Ensure the `.json` file size is non-zero and matching expected record count.

- [ ] **Step 3: Transfer to New Device**
  - Install **PharmaLoka** on the new device.
  - Copy the backup `.json` file via USB/Local Network, OR sign in with Google to download from Drive.

- [ ] **Step 4: Execute Verified Restore**
  - On the new device setup screen, select **Restore from Backup**.
  - Provide admin credentials when prompted to authorize data overwrite.
  - Wait for schema verification and database restoration to complete.

- [ ] **Step 5: Post-Restore Verification**
  - Log in with existing admin credentials.
  - Check **Inventory Catalog** to verify product count and stock batches match.
  - Verify **POS Sales History** and **Shift Logs** match pre-transfer totals.

---

## 🔒 Security & Support
- **Role Permissions Matrix**:
  - `Admin`: Full system access, user management, and database configuration.
  - `Pharmacist`: Catalog management, stock receipt, and expiry audit logs.
  - `Cashier`: POS sales counter and transaction processing.

