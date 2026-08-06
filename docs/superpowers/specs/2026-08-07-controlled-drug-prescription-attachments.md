# Design Spec: Controlled-Drug Prescription Attachments & Compliance Logging

**Goal:** Ensure full regulatory compliance for controlled pharmaceuticals (Narcotics, Psychotropics, Precursors) by mandating digital prescription attachment (camera capture / image import / PDF scan) during POS checkout.

---

## 1. Regulatory Requirements & Flow

- **Trigger Condition**:
  - When any item in the active POS cart has `is_controlled = true` or `requires_prescription = true`.

- **Prescription Metadata Verification**:
  - Doctor Name & License Number (SIP / STR).
  - Patient Name & Address.
  - Digital Image or Document attachment (stored in encrypted local storage).

---

## 2. Storage & Encryption

- **Encrypted Media Storage**:
  - Prescription scans are encrypted with AES-256 using the local app security key before saving to disk.
  - Linked to the transaction record via `prescription_id` and audit log entry.

---

## 3. Compliance Reporting

- **Official Regulatory Export**:
  - Export monthly SIPNAP / MOH compliant reporting logs containing sales, prescription references, doctor details, and batch numbers.
