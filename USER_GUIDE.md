# 📖 Pharmacy Inventory Platform — User Guide & Manual

Welcome to the **Pharmacy Inventory Platform**! This application is an offline-first inventory management and Point-of-Sale (POS) counter system designed specifically for pharmacies, clinics, and drugstores.

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

## 🔒 Security & Support
- **Role Permissions Matrix**:
  - `Admin`: Full system access, user management, and database configuration.
  - `Pharmacist`: Catalog management, stock receipt, and expiry audit logs.
  - `Cashier`: POS sales counter and transaction processing.
