# Design Spec: Indonesian Pharmacy Competitor Analysis & Feature Roadmap

> Inspired by market-leading platforms (*ApotekDigital* and *Farmacare*).

---

## 1. High-Value Roadmap Features

### A. OCR / AI Purchase Invoice Reader (Faktur AI)
- **Problem**: Manual entry of supplier invoices (PBF) is slow and prone to typographical errors in batch numbers and expiry dates.
- **Solution**: Drag & drop or photo capture of PBF invoices $\rightarrow$ local OCR / Gemini Vision API parses supplier name, line items, batch numbers, unit prices, and expiry dates $\rightarrow$ pre-fills receiving purchase orders for 1-click verification.

### B. Compounding / Custom Medicine Module (Obat Racikan)
- **Problem**: Pharmacies frequently prepare custom powder packets (puyer), capsules, or ointments (salep) from raw ingredients/pills.
- **Solution**: Dedicated POS compounding builder. Calculates component costs, dosage warnings, and automatically deducts constituent stock batches via FEFO upon checkout.

### C. Regulatory Reporting Automation (SIPNAP & BPOM Integration)
- **Problem**: Monthly manual compilation of controlled drug sales for Ministry of Health (SIPNAP) and BPOM is labor-intensive.
- **Solution**: 1-click export of official SIPNAP CSV/Excel reports for Narcotics, Psychotropics, and Precursors matching Ministry of Health schema formatting.

### D. Patient Medication History & E-Prescription (E-Resep)
- **Problem**: Difficulty tracking recurring patient prescriptions, chronic disease refill cycles (Prolanis), and prescribing doctor records.
- **Solution**: Patient master database with chronic refill reminders, digital prescription attachments, and doctor prescription analytics.

### E. Advanced Defecta & Supplier Comparison Matrix
- **Problem**: Purchasing managers manually cross-reference supplier prices across multiple PBFs.
- **Solution**: Auto-generated Defecta list with supplier price comparison, minimum order quantities (MOQ), and auto-generated Purchase Orders.
