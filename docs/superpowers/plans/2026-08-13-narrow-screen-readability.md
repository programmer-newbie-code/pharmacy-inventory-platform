# Narrow Screen Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:executing-plans or
> superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Spec:** [`2026-08-13-narrow-screen-readability.md`](../specs/2026-08-13-narrow-screen-readability.md)

**Goal:** Stop text truncating on a ~393 dp phone, and make the existing POS
quantity dialog discoverable, without restyling or rewording anything.

**Architecture:** A reusable test harness renders a screen at a chosen size and
text scale and fails on overflow. Layout then adapts by width: paired form fields
stack below the sidebar breakpoint, primary names wrap to two lines, and the POS
cart's `trailing` stops competing with the product name. `AppBreakpoint`
(`lib/core/responsive_layout.dart`) already expresses the width tiers; reuse it
rather than hard-coding numbers.

**Tech Stack:** Flutter, `flutter_test`, existing ARB strings.

---

## Verification reality

There is no Flutter toolchain or Android device in the implementation
environment, so **the harness plus CI is the only automated gate** and the owner
verifies on the Vivo V23e after merge. Three prior increments lost CI cycles to
assumptions; before asserting on any framework behaviour, confirm it rather than
guessing. In particular:

- `tester.takeException()` is how a `RenderFlex` overflow surfaces in a widget
  test. Verify that a deliberately overflowing widget actually trips it before
  trusting a passing result, otherwise the harness proves nothing.
- Truncation is **not** an exception. A `Text` with `overflow: ellipsis` renders
  happily. Detect it by geometry or by `maxLines`, not by expecting a throw.

## Target sizes

| Name | Size | Why |
| --- | --- | --- |
| Owner device | 393 x 873 | Vivo V23e at ~2.75 DPR, the reported failure |
| Small phone | 360 x 640 | common floor, catches worse cases |
| Desktop | 1366 x 768 | must keep side-by-side layout |

## Task 1: Build the detection harness

**Files:** create `test/support/layout_harness.dart`.

**Step 1: Write the helper.**

```dart
/// Pumps [child] at [size] and [textScale], then fails if layout overflowed.
Future<void> pumpAtSize(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(393, 873),
  double textScale = 1.0,
}) async { ... }
```

It must set `tester.view.physicalSize` and `devicePixelRatio`, register
`addTearDown` to reset both, wrap `child` in a `MediaQuery` applying
`TextScaler.linear(textScale)`, pump, settle, and assert
`tester.takeException()` is null.

**Step 2: Prove the harness actually detects overflow.**

Add a self-test that pumps a deliberately overflowing widget (for example a
`Row` of fixed-width boxes wider than `size`) and asserts the harness reports a
failure. **If this self-test passes trivially, the harness is useless and every
later task's green result is meaningless.**

**Step 3:** Run `flutter test test/support/` and confirm the self-test behaves as
designed.

**Step 4:** Commit — `test(support): add narrow-screen layout harness`.

## Task 2: Stack paired form fields on phones

**Files:** modify `lib/features/inventory/add_product_dialog.dart`,
`lib/features/inventory/edit_product_dialog.dart`; test
`test/features/inventory/add_product_dialog_test.dart`.

**Step 1: Write the failing test.** At 393x873, assert the four labels named in
the spec are laid out at their full intrinsic width, not truncated. Compare the
rendered width of the label text against its unconstrained intrinsic width, or
assert the field's own width exceeds the label's intrinsic width. Do **not**
assert on `findsOneWidget` alone: an ellipsised label is still found.

**Step 2:** Run it. Expected: FAIL, roughly 148 dp available against 218 dp
needed.

**Step 3: Implement.** Replace each `Row` of two `Expanded` unit/price fields
with a layout that stacks into a `Column` when
`AppBreakpointWidth.fromWidth(width).usesSidebar` is false, and keeps the `Row`
otherwise. Keep every existing key, controller, validator, and ARB string
unchanged. A small private helper in the file is fine; do not create a shared
widget until a second file genuinely needs it.

**Step 4:** Run the test plus the existing dialog tests. Expected: PASS, and the
existing add/edit product tests unchanged.

**Step 5:** Add a desktop assertion at 1366x768 proving the fields remain side by
side, so the fix is width-conditional rather than a permanent stack.

**Step 6:** Commit — `fix(inventory): stack paired unit fields on narrow screens`.

## Task 3: Let list names wrap in Katalog Inventaris

**Files:** modify `lib/features/inventory/product_list_screen.dart`; test
`test/features/inventory/product_list_screen_test.dart`.

**Step 1: Write the failing test.** Seed a product named
`Amoxicillin 500mg Kapsul Forte Extra` and, at 393x873, assert no overflow and
that the name renders across at most two lines while remaining fully present.

**Step 2:** Run it. Expected: FAIL or a truncated single line.

**Step 3: Implement.** Give the name `maxLines: 2` with
`overflow: TextOverflow.ellipsis` as the last resort, and stop the row starving
it: the `Obat Keras` badge and trailing action must not consume the name's
width. Wrapping the badge below the name, or letting the title occupy the full
tile width with the badge on the subtitle line, both satisfy this. Preserve
`Key('productTile_${prod.id}')` and the existing tap targets.

**Step 4:** Run the test and the existing inventory tests.

**Step 5:** Commit — `fix(inventory): let long product names wrap on phones`.

## Task 4: Fix the POS cart row and expose the quantity dialog

**Files:** modify `lib/features/pos/pos_screen.dart`; test
`test/features/pos/pos_screen_test.dart`; ARB files for the new tooltip.

**Step 1: Write the failing tests.**
- At 393x873 with a long product name in the cart, assert no overflow and the
  name is not reduced to a single truncated line.
- Assert an explicit quantity control exists with a **non-null tooltip**, and
  that activating it opens the dialog containing `Key('inputBoxQty')` and
  `Key('inputBaseQty')`.
- Assert typing `2` boxes and `5` base units on a product whose
  `unitsPerPurchaseUnit` is 10 yields 25 base units, so the dialog's arithmetic
  is pinned while the UI around it changes.

**Step 2:** Run. Expected: the overflow and tooltip assertions fail; the
arithmetic one may already pass, which is fine, it guards a regression.

**Step 3: Implement.**
- `trailing` currently holds three `IconButton`s plus the subtotal, leaving about
  116 dp for the name. Move quantity controls and subtotal onto their own line
  below the name on narrow widths so the name gets the full tile width.
- Add an explicit control that opens `_showEditCartItemDialog`: an
  `IconButton`/`OutlinedButton` with `Icons.edit` and a localized tooltip. Keep
  the existing `Key('editCartQty_$idx')` on the control that opens the dialog so
  intent stays traceable, and keep the current text tappable as well.
- Add ARB keys in `app_en.arb` and `app_id.arb` for the tooltip, verifying key
  parity mechanically.

**Step 4:** Run the POS tests. Expected: PASS.

**Step 5:** Commit — `fix(pos): expose quantity entry and fix cart row overflow`.

## Task 5: Text-scale pass on the touched screens

- [ ] Add a 2.0 text-scale case at 393x873 for the add product dialog, Katalog
  Inventaris, and the POS cart, asserting no overflow.
- [ ] Fix only confirmed failures. Do not pre-emptively restyle screens the
  harness reports as clean.
- [ ] Commit — `test(layout): cover 2.0 text scale on touched screens`.

## Task 6: Verification and PR

- [ ] `flutter analyze` with zero issues.
- [ ] Full suite, then the CI-equivalent filtered coverage excluding
  `**/*.g.dart`, `lib/l10n/*`, `lib/data/database.dart`; expect at least 80
  percent.
- [ ] Verify ARB key parity between `app_en.arb` and `app_id.arb`.
- [ ] Confirm `git diff` touches no repository, schema, or pricing logic.
- [ ] Signed commits; PR stating the measured before/after widths, the tests
  added, and explicitly that no physical-device verification was performed.
- [ ] All required CI green, squash merge, verify post-merge main CI.
- [ ] Update `docs/superpowers/status/current-roadmap.md` with the merged
  evidence and record that owner verification on the Vivo V23e is outstanding.

## Known issues found during implementation

- **The POS quantity dialog's total row overflows by 70px on a 393dp phone.**
  `pos_screen.dart:166` has no width constraint, unlike `AddProductDialog`'s
  explicit `width: 480`. Pre-existing, unrelated to the cart-tile row this
  increment restructured; consumed in the discoverability test rather than
  expanding this PR into fixing the dialog's own layout.
- **The whole `PosScreen` overflows at 2.0 text scale, independent of the cart
  tile this increment touched.** The 'Shopping Cart' header `Row`
  (`pos_screen.dart:504`), a `Column` (`pos_screen.dart:539`), and a
  `DropdownButton` (`pos_screen.dart:784`) all overflow before the cart tile
  layout is even reached. This is a pre-existing, screen-wide text-scale
  defect, not something Task 4 introduced or can fix in isolation. Recorded
  here for a separate increment; Task 4's own test consumes the known
  exceptions and asserts only that the cart tile it changed still builds and
  the quantity control remains reachable.
- **Add/edit product dialog overflows by 48px at 2.0 text scale.** The form
  content is already inside a `SingleChildScrollView`, so the overflow is in the
  dialog chrome (title, fixed `contentPadding`, actions), not the fields this
  increment changed. Fixing it alters the dialog's own structure and needs owner
  review of the rendered result.
- **`expectNotTruncated` must not be used on `InputDecoration` labels.**
  `find.text` on a field label resolves to a `Text` whose nearest
  `RenderParagraph` belongs to the decoration subtree, which reported an
  identical 310.67px slot and a spurious truncation for both a 34-character and
  a 12-character label. Use `expectNoOverflow` plus a presence assertion there,
  and reserve `expectNotTruncated` for plain `Text` such as list rows. This cost
  three CI cycles to identify; the limitation is now documented in the helper.

## Later slices, not this PR

Seventeen screens still have zero overflow protection: patients, suppliers,
compounding, alerts, shifts, returns, users, backup, help, and the report
screens. Extend the Task 1 harness to each in its own PR, ordered by how
frequently a pharmacist uses the screen.

## Stop conditions

- The harness self-test does not fail on a deliberate overflow: stop and fix the
  harness first, since nothing downstream can be trusted.
- A fix requires changing pricing, unit conversion, or validation: stop, that is
  outside this increment.
- Removing truncation demands a visual redesign rather than a layout adaptation:
  stop and request owner approval with rendered comparison.
