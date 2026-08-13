# Narrow Screen Readability

Child increment of
[`cross-agent modernization roadmap`](2026-08-12-cross-agent-modernization-roadmap.md)
Priority 3 (Android mobile modernization) and Priority 4 (accessibility).

## Evidence

Reported by the owner from a **Vivo V23e** (1080x2400 px, ~2.75 DPR, so about
**393x873 dp**): text in Katalog Inventaris and other pages renders as `...`,
and the POS cart appeared to require tapping `+` once per unit.

Audited at `f837b33`. Three distinct defect classes, each measured rather than
assumed.

### 1. Form field labels truncate in paired rows

`add_product_dialog.dart` places two unit fields in a `Row` of two `Expanded`
children (lines 400-424). The dialog requests `width: 480` but a 393 dp screen
clamps it to about 353 dp, leaving roughly **148 dp per field**:

| Label | Needs | Result |
| --- | --- | --- |
| `Satuan Dasar (mis. tablet, kapsul)` | ~218 dp | truncated |
| `Satuan Beli (mis. box, dus)` | ~173 dp | truncated |
| `HPP per Satuan Dasar (1 Tablet/Pcs)` | ~224 dp | truncated |
| `Harga Beli per Satuan Beli (1 Box/Dus)` | ~243 dp | truncated |

`edit_product_dialog.dart` repeats the pattern with six or more `Expanded`
pairs. This is the `Satuan Dasar...` the owner could not read.

### 2. List row primary text truncates

Katalog Inventaris (`product_list_screen.dart:220`) spends its row width on
`contentPadding` 32 dp, a radius-22 `CircleAvatar` about 56 dp, an
`Obat Keras` badge about 78 dp, and a trailing edit icon about 48 dp, leaving
about **179 dp** for the product name. `Amoxicillin 500mg Kapsul` needs about
175 dp, so it fits by 4 dp at default text size and truncates as soon as the
name is longer or text scaling is enabled.

The POS cart row (`pos_screen.dart:558`) is worse: `trailing` holds three
`IconButton`s plus the subtotal, leaving about **116 dp** for the name.

### 3. The POS quantity dialog is undiscoverable

A free-input quantity dialog with separate purchase-unit and base-unit fields
**already exists** (`pos_screen.dart:96`, delivered in PR #118). It computes
`(boxes x ratio) + baseUnits` with a live subtotal, which is exactly the
capability the owner asked for.

Its only trigger is an `InkWell` wrapping plain bold text in the cart tile
subtitle (`pos_screen.dart:573`). There is no icon, border, tooltip, or any
other affordance, so it reads as a label. `_addToCart` adds exactly 1 base unit
and `_updateQuantity` steps by 1, so a user who cannot find the dialog must tap
`+` 29 times for 30 tablets.

### Systemic cause

`lib/features/` contains **530 `Text` widgets and only 24 with `maxLines` or
`TextOverflow`**, about 4.5 percent. `app_theme.dart` sets sizes but no
overflow default, so there is no safety net. Nineteen screens with list or
table rows have zero protection.

No feature screen is tested at phone width: the only three `takeException`
assertions in the suite are in `home_screen_test.dart` and
`accessibility_workflow_test.dart`, both covering the shell. That is why this
reached a release unnoticed.

## Required behavior

- Primary identifying text (product, patient, supplier, formula names) wraps to
  at most two lines rather than truncating, so a pharmacist can distinguish
  `Amoxicillin 500mg` from `Amoxicillin 500mg Forte`. This is a dispensing
  safety concern, not a cosmetic one.
- Paired form fields stack vertically below the sidebar breakpoint so each label
  gets the full dialog width. Existing ARB wording is unchanged; the layout
  adapts instead.
- Rows keep side-by-side layout at desktop widths, where they already fit.
- The POS quantity dialog is reachable through an explicit, labelled control
  with a tooltip. Its behaviour and the existing key `editCartQty_$idx` are
  preserved.
- No screen produces a `RenderFlex` overflow at 393x873 or at 2.0 text scale.
- No stored value, price calculation, permission, or validation rule changes.

## Non-goals

- Restyling beyond what removing truncation requires. Colour, spacing, and
  typography choices stay as they are.
- Rewording ARB strings. The owner chose to keep the current wording and adapt
  the layout instead.
- Changing `_addToCart` to prompt for quantity. The owner chose to keep
  single-tap add and fix discoverability instead.
- The remaining 17 unprotected screens. They follow in later slices using the
  same harness.
- Physical-device verification, which the agent environment cannot perform.

## Acceptance criteria

1. A reusable test helper renders a screen at a given size and text scale and
   fails on `RenderFlex` overflow.
2. A test proves the four named labels in the add and edit product dialogs are
   fully laid out at 393x873, not truncated.
3. A test proves a long product name renders across at most two lines in Katalog
   Inventaris at 393x873 without overflow.
4. A test proves the POS cart row shows a long product name without overflow at
   393x873.
5. A test proves the POS quantity control is discoverable: an explicit control
   with a non-null tooltip exists, and activating it opens the dialog whose
   purchase-unit and base-unit fields accept typed quantities and compute the
   expected total.
6. A test proves paired unit fields stack below the sidebar breakpoint and stay
   side by side above it.
7. Every affected screen passes at 393x873 and at 2.0 text scale with no
   exception.
8. `flutter analyze` clean, full suite green, CI-filtered coverage at or above
   80 percent, all required CI green, post-merge main CI green.

## Migration and rollback

Presentation only. No schema, repository, or persisted-data change. Rollback is
a code-only revert per slice.

## Risks and controls

- **Unverifiable by the agent:** there is no Flutter toolchain or Android device
  in the implementation environment, so the harness plus CI is the only
  automated gate and the owner verifies on the Vivo V23e after merge. Recorded
  rather than implied.
- **Wrapping changes row height and could push content off screen:** tests
  assert no overflow at the target size rather than only checking the text.
- **A fix that only satisfies the test:** assertions target rendered geometry
  and tooltip presence, not implementation details, and the harness runs at the
  real device size.
- **Regression across the other 17 screens:** the harness is written to be
  reused, so later slices extend coverage rather than reinventing it.
- **Scope creep into visual redesign:** anything beyond removing truncation and
  adding the quantity affordance is out of scope and needs owner approval with
  rendered comparison.
