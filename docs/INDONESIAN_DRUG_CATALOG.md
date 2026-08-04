# Bundled Indonesian drug catalog

`assets/data/indonesian_drugs.csv` is an offline lookup aid for the add-product
form. It contains medicine names, active ingredients, broad category labels,
manufacturer text, and a unit hint. Selecting a row only fills identity fields;
it never invents a barcode, price, supplier, batch, stock, or expiry date.

## Source and limitations

The current file is a curated application seed assembled for offline search. It
is not an official BPOM export, does not contain BPOM registration numbers, and
must not be treated as proof of registration, legal sale status, dosage, or
clinical suitability. Product names and categories can become stale or contain
duplicates/aliases. Pharmacy staff must verify the product against its package
and current official information before selling it.

No third-party license or authoritative BPOM provenance is asserted for this
seed. A verified source, license, and data owner are required before replacing
it with an official dataset.

## Maintenance and update procedure

The catalog maintainer should:

1. Obtain a source whose redistribution terms permit bundling, and record its
   name, retrieval date, license, and field mapping in this document.
2. Keep the five-column UTF-8 schema exactly:
   `name,active_ingredient,category,manufacturer,unit`.
3. Remove empty rows and duplicate identity records; do not add operational
   inventory fields to this lookup file.
4. Run `flutter test test/data/drug_catalog_asset_test.dart` and
   `flutter analyze` before opening a PR.
5. Include the source/version and a short change summary in the PR. Do not
   silently overwrite the catalog as part of an inventory import.

The application validates the file shape in CI so a malformed asset cannot be
released unnoticed. BPOM provenance remains intentionally deferred until a
data owner supplies authoritative source and licensing details.
