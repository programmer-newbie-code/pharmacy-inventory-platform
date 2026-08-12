# Feature Localization Sweep

Child increment of
[`cross-agent modernization roadmap`](2026-08-12-cross-agent-modernization-roadmap.md)
Priority 4 (accessibility, localization, and public documentation).

## Evidence

Audited at commit `325da46` by scanning `lib/` (excluding `lib/l10n/` and
generated `*.g.dart`) for text-rendering constructors and named parameters
(`Text`, `title`, `subtitle`, `label`, `labelText`, `hintText`, `helperText`,
`tooltip`, `message`, `content`, `errorText`, `semanticLabel`) holding string
literals, excluding lines that already reference `l10n.` and excluding
technical values (asset paths, date-format patterns, lowercase keys/codes).

**238 hardcoded user-facing strings remain**, against 359 existing ARB keys:

| Area | Plain literals | Interpolated | Total |
| --- | --- | --- | --- |
| `features/suppliers` | 53 | 9 | 62 |
| `features/inventory` | 46 | 3 | 49 |
| `features/pos` | 29 | 8 | 37 |
| `features/patients` | 19 | 3 | 22 |
| `features/compounding` | 18 | 2 | 20 |
| `features/users` | 12 | 2 | 14 |
| `features/reports` | 12 | 4 | 16 |
| `data/receipt_pdf_service.dart` | 5 | 8 | 13 |
| `features/alerts` | 2 | 1 | 3 |
| `features/settings` | 1 | 0 | 1 |
| `main.dart` | 1 | 0 | 1 |
| **Total** | **198** | **40** | **238** |

`AGENT.md` line 58 requires that UI-facing strings go through ARB files and
that a widget never hard-codes user-facing text. Every row above violates that.

### Mixed-language defect: 23 strings show Indonesian regardless of locale

The app defaults to `id` with an `en` toggle, but these literals are Indonesian,
so an English user sees untranslated Indonesian text:

| Location | Text |
| --- | --- |
| `pos/pos_screen.dart:233` | `Input Modal Kasir (Opening Cash)` |
| `pos/pos_screen.dart:246` | `Modal Awal Kasir / Drawer (Rp)` |
| `pos/pos_screen.dart:255` | `Batal` |
| `pos/pos_screen.dart:378` | `Tarik/Setor Kas (Prive Owner)` |
| `inventory/add_product_dialog.dart:214` | `Tambah Produk Baru` |
| `inventory/add_product_dialog.dart:292` | `Nama Produk *` |
| `inventory/add_product_dialog.dart:367` | `Golongan Obat` |
| `inventory/add_product_dialog.dart:372` | `Obat Bebas (Hijau)` |
| `inventory/add_product_dialog.dart:375` | `Obat Bebas Terbatas (Biru)` |
| `inventory/add_product_dialog.dart:377` | `Obat Keras (Merah)` |
| `inventory/add_product_dialog.dart:549` | `Minimum Stok` |
| `inventory/add_product_dialog.dart:582` | `Obat Keras / Perlu Resep Dokter` |
| `inventory/add_product_dialog.dart:609` | `Batal` |
| `inventory/add_product_dialog.dart:614` | `Simpan Produk` |
| `inventory/edit_product_dialog.dart:409` | `Controlled Substance (Golongan Keras)` |
| `users/user_management_screen.dart:92,191` | `Cashier (Kasir)` |
| `reports/reports_screen.dart:315` | `Laporan Arus Kas & Prive Owner` |
| `reports/sipnap_report_screen.dart:142,144,146` | `Nama Obat`, `Stok Awal`, `Stok Akhir` |
| `data/receipt_pdf_service.dart:86,87` | `Harga`, `Total` |

This is the same class of defect fixed for a single shell string in PR #151;
that increment only covered the strings its spec named, leaving the rest.

## Required behavior

- Every user-facing string in the audited surface resolves through ARB.
- English and Indonesian ARB files stay at key parity, with genuine
  Indonesian translations — not English text copied into `app_id.arb`.
- Interpolated strings become ARB messages with declared placeholders, not
  concatenated fragments, so word order stays translatable.
- Drug-classification values (`Obat Bebas`, `Obat Bebas Terbatas`,
  `Obat Keras`) keep their **stored** values unchanged; only their displayed
  labels are localized. These are persisted data and regulatory categories.
- `lib/data/` must not import localization. Data-layer strings are passed in
  from the caller, matching the `receipt_pdf_service.dart` attribution
  parameter added in PR #151.
- No behavior, layout, permission, validation rule, or stored value changes.

## Non-goals

- Adding a third locale.
- Rewording existing copy, or "improving" any message while moving it.
- Localizing debug output, log messages, exception text, or developer-only
  strings.
- Changing stored drug-classification values, SIPNAP report semantics, or any
  persisted enum.
- Screen-reader, contrast, focus, and text-scale auditing. Those are separate
  Priority 4 concerns and get their own increment.

## Acceptance criteria

1. The audit scan reports zero remaining hardcoded user-facing strings in each
   area a slice claims to have completed.
2. `app_en.arb` and `app_id.arb` are at key parity, verified mechanically.
3. Every interpolated message uses ARB placeholders with declared types.
4. A widget test per completed slice asserts representative strings render from
   ARB in **both** locales, so a regression to hard-coded text fails.
5. A test proves the drug-classification dropdown still stores the original
   values while displaying localized labels.
6. `lib/data/` contains no localization import.
7. Generated localization is clean after build; `flutter analyze` reports no
   issues.
8. Full suite passes, CI-filtered coverage stays at or above 80 percent, PR CI
   is green on all required checks, and post-merge main CI is green for every
   slice.

## Migration and rollback

No schema, repository, or persisted-data change. Rollback is a code-only
revert per slice. Because each slice is an independent PR, a regression in one
area does not require reverting the others.

## Verification strategy

Per slice: the audit scan re-run to prove the area is clean, ARB key-parity
check, widget tests in both `en` and `id`, `flutter analyze`, full test suite,
coverage gate, and CI.

No local Flutter toolchain is available in the implementation environment (no
SDK installed; the Flutter Docker image does not fit the free disk), so CI is
the first execution gate. Slices are deliberately small so a failure is cheap
to diagnose and fix forward.

## Risks and controls

- **Wrong translation changing meaning:** pharmacy and regulatory terms
  (`Obat Keras`, SIPNAP column headers) keep their established Indonesian
  wording; the English side describes rather than transliterates. Flag any
  term whose correct translation is uncertain in the PR instead of guessing.
- **Silently changing stored values:** classification labels are display-only;
  a test pins the stored values.
- **Scope creep into rewording:** move strings verbatim. Copy changes belong to
  a separate product decision.
- **Large diff hiding a behavior change:** one PR per area, each independently
  reviewable and revertable.
- **Placeholder mistakes:** interpolated messages are the highest-risk rows, so
  each gets an assertion on the rendered result, not just on the key existing.
