# Changelog

## 1.8.1

- Fixes truncated field labels and product names that were hard to read on
  smaller phone screens.
- Makes the point-of-sale quantity editor easier to find and use when
  entering an exact box-and-unit amount.
- Shrinks and obfuscates the Android release build to reduce download size
  and raise the difficulty of reverse engineering.

## 1.8.0

- Restores the sign-out, language, help, and pharmacy-branding actions. They
  previously sat in a bar that never appeared, so a signed-in user had no way to
  sign out at any window size.
- Requires an active session before completing a stock receipt, so stock and
  audit records can no longer be attributed to the default administrator.
- Attributes cash movements, shift operations, and printed receipts to the
  cashier actually signed in.
- Lets you recover from a failed receipt save or print instead of losing the
  receipt, with a retry option.
- Reports when an automatic Google Drive backup cannot run because no account is
  connected, instead of skipping it silently.
- Verifies backup integrity with a checksum and records failed restores without
  replacing existing data.
- Stops the barcode camera when the app moves to the background.
- Adds an administrator review for closed cashier shifts.
- Adds best-selling medicine analytics with a custom date range, and exports
  best-selling, procurement, and cash-movement reports to Excel with an audit
  trail.
- Introduces the PharmaLoka identity and new application icons across Windows,
  Android, and the documentation site.
- Corrects screens that showed Indonesian text in the English interface, and
  moves supplier, inventory, point-of-sale, patient, and compounding wording into
  the translation files.
- Lets you choose the receipt folder and edit product and profile photos.

## 1.7.0

- Adds Today, This Week, This Month, This Year, and custom date filters to
  reports.
- Files saved receipt PDFs into automatically organised, date-based folders.

## 1.6.2

- Fixes Google Drive sign-in on Windows, where the browser previously opened with
  a truncated address and could not complete authorisation.

## 1.6.1

- Uses PharmaLoka as the default pharmacy name.

## 1.6.0

- Records cash drawer movements and owner withdrawals, with shift reconciliation.
- Adds dual-unit pricing so a product can be sold by box or by individual unit,
  with remembered custom unit names.
- Publishes an Android App Bundle alongside the APK.

## 1.5.0

- Adds a procurement and purchasing report.
- Prompts for the cashier's opening register amount at checkout.
- Adds net sales analytics and a product edit dialog.
- Prints a Code128 barcode on receipts and adds a pharmacy branding card.
- Supports cancelling a purchase order and browsing recent transactions when
  processing a return.

## 1.4.0

- Adds the SIPNAP monthly regulatory report export.
- Adds compounding (obat racikan) recipe and formula management.
- Adds patient records and electronic prescription management.
- Requires an active cashier shift before checkout.
- Improves supplier management and purchase order receiving.
- Adds a versioned Indonesian drug catalogue with over-the-air updates.
- Notifies you when a newer version of the app has been published.
- Adopts the PolyForm Noncommercial 1.0.0 licence.

## 1.3.5

- Adds a persistent adaptive workspace: a full-height desktop sidebar and a
  mobile-friendly top-level navigation shell.
- Keeps POS usable on phone-width screens with responsive checkout controls.

## 1.3.4

- Shows clear, localized feedback when a Google Drive backup cannot run.
- Adds clearer export progress and failure feedback in reports.
- Labels high-frequency inventory and POS actions for assistive technology.

## 1.3.3

- Published Windows and Android test artifacts.
