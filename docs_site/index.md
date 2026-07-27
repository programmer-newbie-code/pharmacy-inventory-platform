---
layout: default
title: Pharmacy Inventory Platform — Documentation & User Guide
---

# 💊 Pharmacy Inventory Platform

Welcome to the official documentation for the **Pharmacy Inventory Platform** — a secure, offline-first inventory management and Point-of-Sale (POS) counter system built for pharmacies, clinics, and drugstores.

[📥 Download Windows App (.zip)](https://github.com/programmer-newbie-code/pharmacy-inventory-platform/releases/latest) &nbsp;|&nbsp; [📱 Download Android APK (.apk)](https://github.com/programmer-newbie-code/pharmacy-inventory-platform/releases/latest) &nbsp;|&nbsp; [📖 User Manual](#-user-guide--manual)

---

## ✨ Key System Features

### 🛒 1. POS Counter & Automatic FEFO Stock Deduction
* **First-Expired, First-Out (FEFO)**: When sales are checked out, inventory is automatically allocated and deducted from the earliest expiring stock batch first.
* **Controlled Drug Verification**: Mandatory doctor name, patient name, and prescription verification check for controlled drugs (`isControlled`).
* **Minimum Price Safeguard**: Warns cashiers if an item's sell price is accidentally set below base unit cost.
* **Digital Receipt**: Generates printable sales transaction receipts.

### 📦 2. Multi-Unit Inventory Catalog
* **Unit Conversion**: Flexible conversion rules (e.g., 1 Box = 100 Tablets).
* **Batch Receipt**: Track supplier name, batch number, purchase cost, selling price, and expiry dates per delivery batch.
* **Storage Location Tracking**: Assign products to shelf, bin, or refrigerator locations.

### ⚠️ 3. Expiry & Low-Stock Alerts
* **Expiry Watchlist**: Highlights batches expiring within 30, 60, 90, or 180 days with color-coded badges.
* **Reorder Thresholds**: Alerts pharmacists when product stock levels drop below configured reorder thresholds.

### 👥 4. Role-Based Employee Management
* Admin-managed staff accounts with granular roles: `Admin`, `Inventory` (Pharmacist), `Kasir` (Cashier), and `Audit` (Auditor).
* Secure SHA-256 password hashing with random salt.

### 💾 5. Database Backup & BPOM Compliance
* **Atomic Backup & Restore**: Full JSON dataset export and atomic SQLite database restoration inside single transactions.
* **BPOM Regulatory CSV Export**: One-click export of prescription sales logs for regulatory reporting.

---

## 📖 User Guide & Manual

### 1. First-Time Administrator Setup
When launching the platform for the first time on Windows or Android:
1. Enter your full name, desired username, and a strong password.
2. Click **Create Administrator Account**. The system will set up the SQLite database and log you into the Admin dashboard.

### 2. Managing Employee Accounts
1. Log in as an **Admin**.
2. Click **User Management** on the main dashboard.
3. Click **Add Employee Account**, enter username, initial password, and select role (`Kasir`, `Inventory`, or `Audit`).

### 3. Processing POS Counter Sales
1. Navigate to **POS Sales Counter**.
2. Search for items by name or scan barcode using a USB/Bluetooth scanner.
3. Adjust item quantities in the cart.
4. For prescription drugs, fill out doctor and patient details.
5. Click **Complete Sale (Checkout)** to finish the transaction. Stock is automatically deducted following FEFO logic.

### 4. Receiving Stock Batches
1. Open **Inventory Catalog** -> Select Product.
2. Click **Receive Stock Batch**.
3. Input Batch Number, Supplier, Expiry Date, Received Quantity, Cost Price, and Selling Price.

---

## 💻 Tech Stack & Architecture

* **Framework**: Flutter (Dart)
* **Local Database**: Drift (SQLite) with reactive streams
* **State Management**: Flutter Riverpod
* **Localization**: Flutter Gen L10n (Indonesian `id` & English `en`)
* **Security**: SHA-256 password hashing with random salt
* **CI/CD Pipeline**: Automated linting, unit testing (80% coverage gate), multiplatform release builds (Windows & Android), and Jekyll documentation hosting on GitHub Pages.

---

## 🚀 Developer Getting Started

```bash
# 1. Clone repository
git clone https://github.com/programmer-newbie-code/pharmacy-inventory-platform.git
cd pharmacy-inventory-platform

# 2. Install dependencies
flutter pub get

# 3. Generate database code
dart run build_runner build --delete-conflicting-outputs

# 4. Run tests
flutter test

# 5. Run application
flutter run -d windows
```
