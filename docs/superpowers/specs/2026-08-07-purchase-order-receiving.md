# Design Spec: Purchase Order Receiving Enhancement

Date: 2026-08-07

## Problem

Supplier management is minimal (create + list only). The PO receiving flow exists
in the repository layer but lacks:
- Full supplier CRUD with business fields (payment terms, lead time)
- A receiving UI that shows ordered vs received quantities side-by-side
- Discrepancy tracking when delivered quantities don't match the order
- Active/inactive supplier filtering

## Solution

### Schema Changes
- **Suppliers table**: add `payment_terms`, `lead_time_days`, `is_active`, `updated_at`
- **New table `purchase_receiving_items`**: tracks each line item in a receiving
  session with ordered qty, received qty, batch number, expiry, cost, and
  discrepancy reason

### Supplier Repository Enhancement
- Full CRUD (create, read, update, deactivate/reactivate)
- Search by name
- Filter by active/inactive status

### Purchase Receiving Repository (NEW)
- `processReceiving()` — atomic transaction that inserts receiving records,
  creates stock batches, updates PO line items, and sets PO status
- `getReceivingHistory()` — list all receiving sessions for a PO
- `getDiscrepancies()` — filter for lines with qty mismatches

### UI Screens
- **Supplier Detail Screen** — view/edit supplier with contact info, payment
  terms, lead time; shows PO history tab
- **Supplier List Screen** — enhanced with search bar and active/inactive filter
- **Purchase Receiving Screen** — scan/search items, side-by-side ordered vs
  received qty, batch + expiry entry, complete receiving button

## Out of Scope
- AI/OCR invoice scanning (deferred to future spec)
- Multi-currency supplier pricing
- Supplier payment tracking
