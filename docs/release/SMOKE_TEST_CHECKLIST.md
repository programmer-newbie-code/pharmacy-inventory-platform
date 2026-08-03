# 🧪 Pharmacy Platform Release Smoke Test Checklist

> **Manual Smoke Test Checklist**
> Perform before every production version release on Windows and Android.

---

## 💻 1. Windows Desktop Smoke Test
- [ ] **First Launch**: App launches smoothly without crashing; Admin setup screen appears if database is clean.
- [ ] **Admin Authentication**: Login with Admin credentials succeeds; role badge displays `ADMIN`.
- [ ] **Inventory Catalog**: Browse products, search by name, filter by category; create a new product item.
- [ ] **Stock Batch Receipt**: Receive a new batch with batch number, supplier, cost price, and expiry date.
- [ ] **POS Counter**: Add items to cart, verify unit conversion calculations, complete cash checkout.
- [ ] **Receipt Printing**: Print receipt or verify preview dialog renders cleanly.

---

## 📱 2. Android Mobile Smoke Test
- [ ] **Install & Launch**: Install APK on physical Android device; app launches in portrait mode.
- [ ] **Barcode Scanner**: Tap barcode scanner icon, grant camera permission, scan physical medicine barcode.
- [ ] **Touch Interface**: Touch controls, dialogs, dropdowns, and date pickers respond immediately without UI overflow.
- [ ] **Language Toggle**: Tap language icon to toggle between Bahasa Indonesia (🇮🇩) and English (🇬🇧).

---

## 💾 3. Backup & Restore Smoke Test
- [ ] **Local Backup**: Navigate to Backup screen -> Click **Create Local Backup** -> Verify JSON file is created.
- [ ] **Database Restore**: Overwrite/Restore from backup -> Verify product counts and sales history are intact.
- [ ] **Google Drive Backup**: Perform cloud backup sync -> Verify success indicator and audit trail log.

---

## 💊 4. Controlled Drug & Compliance Test
- [ ] Add a controlled drug (`isControlled: true`) to POS cart.
- [ ] Verify checkout is blocked until Doctor Name, Patient Name, and Prescription Verified checkbox are filled.
- [ ] Complete sale and verify prescription details are recorded in `exportPrescriptionSalesCsv()`.
