# 🚀 Pharmacy Platform Release Checklist Template

> **Release Checklist Template**
> Use this checklist for every official platform release (`v1.x.x`).

---

## 📋 1. Pre-Release Technical Verification
- [ ] Run local `flutter analyze` — verify zero warnings and zero errors.
- [ ] Run local `flutter test --coverage` — verify all unit & widget tests pass 100% green.
- [ ] Run `dart run build_runner build --delete-conflicting-outputs` — ensure no generated `.g.dart` drift files are dirty.
- [ ] Verify localization files (`flutter gen-l10n`) match ARB templates without untranslated keys.

---

## 📦 2. Build & Packaging Verification
- [ ] **Windows Desktop Build**:
  - Run `flutter build windows --release`.
  - Verify executable builds in `build/windows/x64/runner/Release/`.
- [ ] **Android Mobile Build**:
  - Run `flutter build apk --release` and `flutter build appbundle --release`.
  - Verify signed APK/AAB artifacts in `build/app/outputs/flutter-apk/`.

---

## 🛡️ 3. Dependency & License Audit
- [ ] Run `flutter pub outdated` — review outdated packages and apply security patches.
- [ ] Verify all pubspec dependencies use compatible open-source licenses (MIT, BSD, Apache 2.0) and project code adheres to PolyForm Noncommercial 1.0.0.
- [ ] Audit `.github/workflows/ci.yml` — verify GitHub Actions use pinned SHAs or audited action versions.

---

## 🧪 4. Manual Smoke Test Protocol
- [ ] Complete all steps in [`docs/release/SMOKE_TEST_CHECKLIST.md`](file:///c:/Users/Davit/Documents/Code/Pharmacy/pharmacy-inventory-platform/docs/release/SMOKE_TEST_CHECKLIST.md) on both Windows and Android test devices.
- [ ] **Android release builds are shrunk and obfuscated (R8 + `--obfuscate`).**
  `flutter test` never exercises the R8/AOT pipeline a release build goes
  through, so a green CI run does **not** prove the shrunk binary works on a
  device — only that it compiles and the existing test suite passes. Before
  distributing an Android release, install the actual release APK/AAB on a
  real device and specifically verify:
  - Google Drive sign-in and backup (`google_sign_in`)
  - Barcode/camera scanning (`mobile_scanner`)
  - Any inventory/database screen (`sqlite3_flutter_libs`)

  These three plugins touch native/JNI code and are the most likely to need
  an explicit ProGuard keep rule that R8 could otherwise strip.

---

## 🗝️ 4a. Android Debug Symbols (for decoding crash reports)

Each Android release build produces Dart obfuscation symbols
(`--split-debug-info`). They are uploaded as a **private** CI artifact named
`android-debug-symbols-<tag>`, retained for 90 days, and attached only to
that build's GitHub Actions run — never to the public GitHub Release.

- [ ] If a crash report ever needs decoding, download the matching
  `android-debug-symbols-<tag>` artifact from that tag's Actions run and use
  `flutter symbolize`.
- [ ] If more than 90 days have passed and the artifact has expired,
  re-run the build from the tagged commit to regenerate matching symbols
  rather than assuming the artifact is still available.

---

## 🏷️ 5. Automated Release Tagging Procedure (SemVer `vX.Y.Z`)

> [!IMPORTANT]
> **Do NOT manually edit `pubspec.yaml` to bump versions!** Versioning is 100% automated. GitHub CI extracts the exact version directly from your git tag (`vX.Y.Z`) and auto-injects it into `pubspec.yaml` and binary metadata during the build step.

- [ ] Ensure all feature PRs are merged to `main` with passing CI.
- [ ] Determine the next version number following Semantic Versioning (`v<MAJOR>.<MINOR>.<PATCH>` e.g., `v1.3.1`, `v1.4.0`, `v2.0.0`).
- [ ] Create annotated git tag on `main`: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`.
- [ ] Push tag to origin: `git push origin vX.Y.Z`.
- [ ] GitHub Actions CI automatically extracts the version from the git tag, injects it into Windows and Android builds, and publishes the release binaries automatically!



