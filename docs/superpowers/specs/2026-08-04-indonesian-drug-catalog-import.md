# Indonesian Drug Catalog and CSV Import

Date: 2026-08-04

## Problem

The bundled `assets/data/indonesian_drugs.csv` is used by product lookup, but
it is not an inventory-import file: it has only name, active ingredient,
category, manufacturer, and unit. The inventory CSV importer needs barcode,
internal code, commercial pricing, and operational stock settings. The current
preview also silently substitutes invalid numeric values and can expose raw
errors after a partial write.

## Users and scope

Inventory staff can search the bundled catalog while adding a product and use a
separate inventory CSV import to create sellable products. Selecting a catalog
result fills only medicine identity fields; staff must explicitly provide the
barcode, internal code, prices, stock, supplier, batch, and expiry information.

The CSV flow validates before writing, previews the result, skips duplicates,
reports invalid rows clearly, and does not create a partial import if a write
fails unexpectedly.

## Non-goals

- Do not silently create sellable inventory from the bundled catalog.
- Do not invent barcodes, prices, suppliers, stock, batches, or expiry dates.
- Do not represent the bundled catalog as an official BPOM dataset or claim a
  current regulatory status for its records.

## Acceptance criteria

- The app bundles and searches the Indonesian catalog offline; its fields map
  only to product identity fields in the add-product workflow.
- CSV preview rejects missing identity fields, duplicate barcodes/internal
  codes (both in-file and already stored), malformed or non-positive numeric
  fields, and malformed controlled-drug values.
- Preview performs no writes. Commit follows an explicit all-or-nothing policy
  for valid rows, while already-invalid/duplicate rows remain skipped and are
  reported before commit.
- UI explains the catalog/import distinction, shows a preview and outcome, and
  contains Indonesian and English ARB strings rather than raw exceptions.
- Documentation states the local-source limitation, maintenance owner, and
  update procedure. Real BPOM provenance/licensing remains an external data
  governance decision until a verified source is supplied.

## Platform and manual verification

Windows and Android both use the same staged file-picker flow. Verify a UTF-8
CSV with Indonesian medicine names, a duplicate, an invalid number, and a
database-conflict case. On a physical Android device, verify picker cancel and
completion states.
