# PharmaLoka Professional Branding and Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the owner-approved PharmaLoka Loka Bloom icon and display
branding across Windows, Android, web, documentation, and store-ready assets.

**Architecture:** Hand-author one canonical SVG plus a full-bleed maskable SVG,
then generate every raster/ICO derivative with a checked-in deterministic
script. Keep stable package and distribution identities untouched while
changing only user-visible product and publisher names.

**Tech Stack:** SVG, Python/Pillow, headless Chromium/Edge, Flutter, ARB,
Android adaptive icons, Windows ICO/MSIX, Jekyll.

---

### Task 1: Pin the approved asset and naming contract

**Files:**
- Create: `test/branding/pharmaloka_brand_assets_test.dart`
- Create: `docs/superpowers/specs/2026-08-12-professional-branding-icon.md`

- [ ] Write a test that reads the future SVG, PNG, ICO, Android adaptive XML,
  user-visible platform configuration, and stable identity files.
- [ ] Assert SVG view box, approved color tokens, absence of `<text`, PNG
  dimensions, ICO size entries, adaptive-resource references, PharmaLoka
  display names, ProgrammerNewbie Studio publisher name, and unchanged
  application/MSIX/binary identifiers.
- [ ] Run:
  `flutter test test/branding/pharmaloka_brand_assets_test.dart`
- [ ] Confirm RED because `assets/branding/app_icon.svg` and the new display
  names do not exist.

### Task 2: Create canonical vector artwork and reproducible exports

**Files:**
- Create: `assets/branding/app_icon.svg`
- Create: `assets/branding/app_icon_maskable.svg`
- Create: `scripts/generate_brand_assets.py`
- Replace: `assets/branding/app_icon.png`
- Replace: `assets/branding/app_icon_source.png`
- Create: `assets/branding/play_store_icon.png`
- Replace: `windows/runner/resources/app_icon.ico`
- Replace: `android/app/src/main/res/mipmap-*/ic_launcher.png`
- Create: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
- Create: `android/app/src/main/res/values/colors.xml`
- Replace: `web/favicon.png`
- Replace: `web/icons/Icon-192.png`
- Replace: `web/icons/Icon-512.png`
- Replace: `web/icons/Icon-maskable-192.png`
- Replace: `web/icons/Icon-maskable-512.png`
- Create: `docs_site/assets/images/pharmaloka-icon.svg`
- Create: `docs_site/assets/images/favicon.png`

- [ ] Author exact `0 0 1024 1024` SVG geometry and palette from the approved
  spec. Use one broken orbit and no dots/text.
- [ ] Author the full-bleed maskable source and matching Android vector
  foreground with all meaning inside the adaptive safe zone.
- [ ] Implement `scripts/generate_brand_assets.py` to locate Chrome/Edge,
  render SVG sources at 1024 px, downsample with Pillow LANCZOS, write the ICO
  size set, and copy documentation sources.
- [ ] Run `python scripts/generate_brand_assets.py`.
- [ ] Inspect generated dimensions and transparency with the branding test.

### Task 3: Apply PharmaLoka display branding

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/main.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_id.arb`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `windows/runner/main.cpp`
- Modify: `windows/runner/Runner.rc`
- Modify: `web/manifest.json`
- Modify: `web/index.html`
- Modify: `docs_site/_config.yml`
- Modify: `docs_site/_layouts/default.html`
- Modify: `docs_site/index.md`
- Modify: `README.md`
- Modify: `USER_GUIDE.md`
- Modify: `docs/INSTALLATION.md`
- Modify: `LICENSE`

- [ ] Replace user-visible product names with PharmaLoka and publisher display
  names with ProgrammerNewbie Studio.
- [ ] Add Android `roundIcon`, web/docs favicon references, and PharmaLoka web
  manifest metadata.
- [ ] Preserve `pharmacy_inventory_platform`,
  `com.programmernewbiecode.pharmacy_inventory_platform`,
  `com.programmernewbiecode.pharmacyinventory`, and
  `pharmacy_inventory_platform.exe`.
- [ ] Run `flutter gen-l10n` and the branding test; confirm GREEN.

### Task 4: Produce visual approval evidence

**Files:**
- Create: `docs/superpowers/evidence/2026-08-13-pharmaloka-icon-review.png`

- [ ] Compose a deterministic review sheet from generated assets showing 1024,
  64, 32, and 16 px renders on light and dark surfaces.
- [ ] Inspect the sheet for blur, clipping, mask safety, off-center geometry,
  thin strokes, and color contrast.
- [ ] Attach the sheet to the PR description and obtain owner approval before
  merge. The owner approved direction A; this gate confirms final execution.

### Task 5: Verify and deliver

- [ ] Run `dart format` on changed Dart files and
  `dart run build_runner build --delete-conflicting-outputs`.
- [ ] Run `flutter gen-l10n`, `flutter analyze`, focused tests, and
  `flutter test --coverage`.
- [ ] Calculate CI-equivalent filtered line coverage and require at least 80%.
- [ ] Run `flutter build windows`; rely on PR CI for Android because the local
  Android SDK is unavailable.
- [ ] Restore unrelated generated platform files and run `git diff --check`.
- [ ] Create a signed commit and fully described PR with the review sheet.
- [ ] Wait for every required check; fix forward from exact logs.
- [ ] Obtain final visual approval, squash-merge only green, verify exact
  post-merge main CI, and update `docs/superpowers/status/current-roadmap.md`.

## Self-review result

- Every asset and naming requirement in the approved spec maps to Tasks 1-4.
- Stable technical identifiers are explicitly pinned by tests and never renamed.
- Raster generation is reproducible from SVG rather than from AI preview pixels.
- Visual approval is required after final deterministic rendering and before
  merge.
