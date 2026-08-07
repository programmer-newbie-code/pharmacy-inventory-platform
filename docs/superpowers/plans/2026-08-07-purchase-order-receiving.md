# Implementation Plan: Purchase Order Receiving Enhancement

Date: 2026-08-07
Branch: `feat/purchase-order-receiving`

## Tasks

1. **Schema migration (v4 → v5)**
   - Add `payment_terms`, `lead_time_days`, `is_active`, `updated_at` to `suppliers`
   - Create `purchase_receiving_items` table
   - Register table in `@DriftDatabase`

2. **Enhance `supplier_repository.dart`**
   - Add `updateSupplier`, `deactivateSupplier`, `activateSupplier`
   - Add `listActiveSuppliers`, `searchSuppliers`, `getSupplier`

3. **Create `purchase_receiving_repository.dart`**
   - `processReceiving()` — transactional receiving
   - `getReceivingHistory()`, `getDiscrepancies()`

4. **Register provider in `providers.dart`**
   - Add `purchaseReceivingRepositoryProvider`

5. **Enhance `supplier_list_screen.dart`**
   - Add search bar
   - Add active/inactive toggle filter
   - Tap to navigate to supplier detail
   - Update add dialog with new fields

6. **Create `supplier_detail_screen.dart`**
   - Full edit form with all fields
   - PO history tab

7. **Create `purchase_receiving_screen.dart`**
   - Ordered vs received side-by-side view
   - Batch + expiry entry per line
   - Complete receiving action

8. **Write tests**
   - Unit: supplier CRUD, receiving creates batches, discrepancy flagging
   - Widget: supplier list search, supplier detail edit

9. **Run local pre-flight**
   - `flutter pub run build_runner build`
   - `flutter analyze`
   - `flutter test --coverage`

10. **Push branch + create PR**

## Verification
- All 5 CI jobs green
- Schema migration tested from v4
- ARB strings added for id + en
