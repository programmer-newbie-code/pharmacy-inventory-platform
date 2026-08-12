# Feature Localization Sweep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:executing-plans or
> superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Spec:** [`2026-08-12-feature-localization-sweep.md`](../specs/2026-08-12-feature-localization-sweep.md)

**Goal:** Move all 238 hardcoded user-facing strings to ARB, in independently
reviewable slices, without changing behavior, layout, or stored values.

**Architecture:** No structural change. Each slice adds keys to
`app_en.arb`/`app_id.arb` and replaces literals in one feature area with
`l10n.<key>`. Interpolated strings become ARB messages with declared
placeholders. `lib/data/` receives strings as parameters rather than importing
localization, preserving the layering rule.

**Tech Stack:** Flutter, ARB localization, `flutter_test`.

---

## Verification note

No local Flutter/Dart SDK is available (no install; the Flutter Docker image
does not fit the free disk). CI is the first execution gate. Keep slices small.
Two prior increments lost cycles to unverified assumptions — verify framework
and package behavior before asserting on it.

## Shared tooling: the audit scan

Before slicing, save the audit scan so every slice can prove its area is clean.

`scripts/audit_hardcoded_strings.py` is added by this increment's first PR,
alongside the spec and plan. It walks `lib/`, skips `lib/l10n/` and `*.g.dart`,
matches text-rendering constructors and named parameters holding literals, skips
lines containing `l10n.`, and skips technical values (asset paths, date patterns,
lowercase keys).

```bash
python3 scripts/audit_hardcoded_strings.py                 # whole lib/, 198 rows
python3 scripts/audit_hardcoded_strings.py lib/features/pos
python3 scripts/audit_hardcoded_strings.py --indonesian    # 23 mixed-language rows
```

It exits 1 when rows remain, so a slice can gate on it. Verified to reproduce
the spec's per-area table exactly. It is a developer tool, deliberately outside
`lib/` so it is not shipped or coverage-gated.

## Slice ordering

Ordered by user-visible harm, then by size. Each slice is a complete PR: green
CI, squash merge, verified post-merge main CI, then the roadmap update.

| Slice | Area | Strings | Why this position |
| --- | --- | --- | --- |
| 1 | mixed-language strings only, across all areas | 23 | Users literally see the wrong language today |
| 2 | `features/suppliers` | 62 | Largest remaining area |
| 3 | `features/inventory` | 49 | Second largest; includes classification labels |
| 4 | `features/pos` | 37 | High-frequency workflow |
| 5 | `features/patients` + `features/compounding` | 42 | Related clinical screens |
| 6 | `features/users` + `features/reports` | 30 | |
| 7 | `data/receipt_pdf_service.dart` + `alerts` + `settings` + `main.dart` | 18 | Data-layer parameter passing needs care |

---

### Slice 1: fix the mixed-language strings

The only slice that crosses area boundaries, because the defect is one class of
bug: Indonesian literals shown to English users.

**Step 1: Write the failing test.**

In `test/features/inventory/add_product_dialog_test.dart` (and the equivalent
POS/users/reports tests), pump the widget with `locale: Locale('en')` and assert
the English string is present and the Indonesian literal is absent:

```dart
expect(find.text('Tambah Produk Baru'), findsNothing);
expect(find.text('Add New Product'), findsOneWidget);
```

**Step 2:** Run the affected tests. Expected: FAIL — the Indonesian literal is
still hard-coded.

**Step 3:** Add ARB keys for the 23 strings in the spec's table to both locales.
For the drug classifications, the Indonesian side keeps the established wording
(`Obat Bebas (Hijau)`), and the English side describes it
(`Over-the-counter (green)`), because these are regulatory categories rather
than free copy.

**Step 4:** Replace the literals with `l10n.<key>`.

**Step 5:** Add the stored-value test required by acceptance criterion 5: select
each classification in the dropdown and assert the value written to the product
is still `Obat Bebas` / `Obat Bebas Terbatas` / `Obat Keras`. **Only the label
is localized; the stored value must not change.**

**Step 6:** Run the suite, then commit —
`localize(app): fix strings shown in the wrong language`.

### Slices 2 through 6: per-area sweeps

Identical procedure per area. Substitute the area name and test files.

**Step 1:** Run `python3 scripts/audit_hardcoded_strings.py lib/features/<area>`
and record the exact list. This is the slice's definition of done.

**Step 2: Write the failing test.** In that area's existing widget test, assert
two or three representative strings render from ARB in **both** locales. Prefer
strings that already appear in assertions so the diff stays small.

**Step 3:** Run it. Expected: FAIL for the `id` case where the literal is
English, or for the `en` case where it is Indonesian.

**Step 4:** Add ARB keys for the area to both locales. Naming: `<area><Thing>`,
matching the existing convention (for example `supplierDetailTitle`,
`supplierNameRequired`). Reuse an existing key rather than adding a duplicate —
check for one first, since 359 keys already exist and several generic actions
(save, cancel, delete, retry) are already defined.

**Step 5:** Replace literals with `l10n.<key>`. Move text **verbatim**; do not
reword while moving.

**Step 6:** For interpolated strings, declare placeholders in the ARB entry:

```json
"receiveDeliveryFor": "Receive delivery for {poNumber}",
"@receiveDeliveryFor": {"placeholders": {"poNumber": {}}}
```

Never concatenate fragments — word order differs between locales.

**Step 7:** Re-run the area scan and confirm it reports zero.

**Step 8:** Verify ARB key parity:

```bash
python3 -c "
import json
en=json.load(open('lib/l10n/app_en.arb',encoding='utf-8'))
idn=json.load(open('lib/l10n/app_id.arb',encoding='utf-8'))
e={k for k in en if not k.startswith('@')}
i={k for k in idn if not k.startswith('@')}
assert not e^i, ('mismatch', e-i, i-e)
print('parity ok', len(e), 'keys')
"
```

**Step 9:** Run the full suite, then commit — `localize(<area>): move strings to ARB`.

### Slice 7: data layer and stragglers

**Step 1:** Run the scan for `lib/data/receipt_pdf_service.dart`,
`lib/features/alerts`, `lib/features/settings`, and `lib/main.dart`.

**Step 2:** For `receipt_pdf_service.dart`, **do not import localization into
`lib/data/`.** Add named parameters with the current literal as the default,
exactly as `poweredByAttribution` was added in PR #151, and pass localized
values from `receipt_dialog.dart`. Verify existing
`test/data/receipt_pdf_service_test.dart` still passes without supplying the new
parameters, so the defaults preserve current behavior.

**Step 3:** Assert `lib/data/` has no localization import:

```bash
! grep -rn "app_localizations" lib/data/
```

**Step 4:** Complete the remaining widget strings, run the suite, commit —
`localize(data,alerts,settings): move remaining strings to ARB`.

### Per-slice completion checklist

- [ ] Area scan reports zero remaining strings.
- [ ] ARB key parity verified mechanically.
- [ ] Both-locale widget assertions added.
- [ ] `flutter analyze` clean.
- [ ] Full suite green; filtered coverage at or above 80 percent.
- [ ] Signed commits; PR states scope, tests, risks, and any uncertain
      translation explicitly.
- [ ] All required CI checks green; squash merge; post-merge main CI green.
- [ ] `docs/superpowers/status/current-roadmap.md` updated with the merged
      evidence before the next slice starts.

## Stop conditions

Stop and ask rather than guessing if:

- A term's correct Indonesian or English equivalent is genuinely ambiguous,
  especially regulatory or clinical vocabulary.
- A string turns out to be a stored value, not a label.
- Localizing a string would require restructuring a widget or changing
  validation, which is outside this increment.
