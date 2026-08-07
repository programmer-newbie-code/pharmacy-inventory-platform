# Design Spec: Patient Records & E-Prescription

Date: 2026-08-07

## Problem
Pharmacies need to track recurring patient purchases, chronic disease refills
(Prolanis), allergies, and doctor prescription records. Currently, only
free-text `patientName` is stored on `sale_transactions`.

## Solution

### Schema Changes
- **Patients table**: `id`, `name`, `phone`, `date_of_birth`, `address`, `allergies`,
  `chronic_conditions`, `notes`, `created_at`, `updated_at`
- **Prescriptions table**: `id`, `patient_id`, `transaction_id`, `doctor_name`,
  `doctor_sip_no`, `clinic_name`, `prescription_date`, `photo_path`, `notes`,
  `is_chronic`, `refill_interval_days`, `next_refill_date`
- **Link `sale_transactions.patient_id`** to `patients.id`

### Patient & Prescription Repositories
- Patient CRUD, search by name/phone, medication history query
- Prescription CRUD, list by patient, query upcoming chronic refills

### UI Screens
- **Patient List Screen**: Searchable list with quick add action
- **Patient Form Screen**: Create/edit patient details, allergies, chronic conditions
- **Patient Detail Screen**: Tabbed view (Info | History | Prescriptions)

## Out of Scope
- Direct SMS/WhatsApp refill reminder dispatch (deferred to phase 2)
