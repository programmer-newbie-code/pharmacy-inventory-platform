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
- [ ] Verify all pubspec dependencies use permissive open-source licenses (MIT, BSD, Apache 2.0).
- [ ] Audit `.github/workflows/ci.yml` — verify GitHub Actions use pinned SHAs or audited action versions.

---

## 🧪 4. Manual Smoke Test Protocol
- [ ] Complete all steps in [`docs/release/SMOKE_TEST_CHECKLIST.md`](file:///c:/Users/Davit/Documents/Code/Pharmacy/pharmacy-inventory-platform/docs/release/SMOKE_TEST_CHECKLIST.md) on both Windows and Android test devices.

---

## 🏷️ 5. Version Bump & Tagging Procedure
- [ ] Increment `version` string in `pubspec.yaml` (e.g., `1.3.0+4`).
- [ ] Commit version bump via PR: `chore(release): bump version to 1.3.0+4`.
- [ ] Merge PR after ALL GitHub Actions CI checks pass 100% GREEN.
- [ ] Create annotated git tag on `main`: `git tag -a v1.3.0 -m "Release v1.3.0"`.
- [ ] Push tag to origin: `git push origin v1.3.0` to trigger automated release workflow.
