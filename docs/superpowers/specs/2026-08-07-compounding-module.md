# Design Spec: Compounding / Obat Racikan Module

Date: 2026-08-07

## Problem
Pharmacies frequently prepare custom powder packets (puyer), capsules, or ointments
from raw ingredients/pills. Manually tracking inventory deductions for each constituent
drug is error-prone.

## Solution

### Schema Changes
- **CompoundingFormulas**: `id`, `name`, `dosage_form`, `yield_quantity`, `yield_unit`, `description`, `preparation_notes`
- **CompoundingIngredients**: `id`, `formula_id`, `product_id`, `qty_per_yield`, `is_active_ingredient`, `notes`
- **CompoundingTransactions**: `id`, `formula_id`, `transaction_id`, `custom_name`, `total_component_cost`, `sell_price`, `qty_prepared`
- **CompoundingTransactionItems**: `id`, `compounding_transaction_id`, `product_id`, `batch_id`, `qty_used`, `unit_cost`

### Compounding Repository
- Formula CRUD and ingredient management
- Cost calculations based on ingredient unit costs

### UI Screens
- **FormulaListScreen**: Searchable list of saved compounding recipes
- **FormulaEditorScreen**: Recipe builder allowing component drug selection and dosage unit specification

## Out of Scope
- Automated pill crushing machine IoT integration (out of scope)
