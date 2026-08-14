# Android Shrink and Obfuscate Release Builds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:executing-plans.
> Steps use checkbox (`- [ ]`) syntax.

**Spec:** [`2026-08-14-android-shrink-obfuscate.md`](../specs/2026-08-14-android-shrink-obfuscate.md)

**Goal:** Shrink and obfuscate Android release builds without touching
signing, APK splitting, or the Windows build.

**Architecture:** Gradle-level R8 configuration plus two `flutter build` CI
flags. No Dart application code changes.

**Tech Stack:** Gradle/R8, Flutter CLI (`--obfuscate`, `--split-debug-info`),
GitHub Actions (`actions/upload-artifact`).

---

## Verification reality

No Android device or local Flutter toolchain exists in this environment. CI
proves the build compiles and the existing test suite passes; it cannot prove
a shrunk release binary runs correctly on a device, because `flutter test`
never exercises the R8/AOT pipeline. State this explicitly in the PR. Do not
claim device verification that did not happen.

## Task 1: Enable R8 shrinking in Gradle

**Files:** modify `android/app/build.gradle`; create
`android/app/proguard-rules.pro`.

**Step 1:** Add a baseline `proguard-rules.pro`. Start from Flutter's own
documented defaults (already applied via
`getDefaultProguardFile('proguard-android-optimize.txt')`) plus the small set
of keep rules Flutter's deployment guide recommends for its own engine
classes. Do not add rules for `sqlite3_flutter_libs`, `mobile_scanner`, or
`google_sign_in` internals — modern plugin AARs bundle their own consumer
ProGuard rules, which R8 merges automatically. Adding untested rules for their
internals risks masking a real missing-rule crash instead of fixing it.

**Step 2:** Update the `release` block:

```gradle
buildTypes {
    release {
        signingConfig signingConfigs.debug
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

Confirm `signingConfig signingConfigs.debug` is untouched — diff the file
after editing and check only the three new lines were added.

**Step 3:** Commit — `build(android): enable R8 shrinking for release builds`.

## Task 2: Add obfuscation and debug symbols to CI

**Files:** modify `.github/workflows/ci.yml`.

**Step 1:** Locate the `flutter build apk --release ...` and `flutter build
appbundle --release ...` steps (the ones with `--build-name`/`--build-number`,
inside the tag-triggered release job). Append:

```
--obfuscate --split-debug-info=build/symbols
```

to both. Do **not** add `--split-per-abi` to either — the owner chose to keep
a single universal APK.

**Step 2:** Confirm the Windows build step in the same workflow is untouched —
diff the file and check no lines changed outside the two Android build steps
and the new upload step from Task 3.

**Step 3:** Commit — `ci(android): obfuscate release builds and split debug info`.

## Task 3: Store debug symbols privately

**Files:** modify `.github/workflows/ci.yml`.

**Step 1:** After the Android build steps, add an `actions/upload-artifact@v4`
step uploading `build/symbols/`:

```yaml
- name: Upload Android debug symbols (private)
  uses: actions/upload-artifact@v4
  with:
    name: android-debug-symbols-${{ github.run_number }}
    path: build/symbols/
    retention-days: 90
```

Verify this step is **not** part of the `create-release` job that publishes
public GitHub Release assets — it must remain a workflow-run artifact only,
visible in the Actions tab to repo collaborators, never public.

**Step 2:** Commit — `ci(android): upload debug symbols as a private artifact`.

## Task 4: Document where the symbols live

**Files:** modify `docs/release/RELEASE_CHECKLIST.md`.

**Step 1:** Add a short note: after a tagged release build, the Android debug
symbols needed to decode a future obfuscated crash stack trace are attached to
that tag's CI run as a private artifact (`android-debug-symbols-<run-number>`),
retained 90 days. If a crash needs decoding after that window, re-run the
build from the tagged commit to regenerate matching symbols.

**Step 2:** Add the three flows the owner should smoke-test on the next
release build before distributing it, since R8 shrinking can break
native/JNI-dependent plugins in ways invisible to `flutter test`:
- Google Drive sign-in and backup (`google_sign_in`)
- Barcode/camera scanning (`mobile_scanner`)
- Any inventory/database screen (`sqlite3_flutter_libs`)

**Step 3:** Commit — `docs(release): record debug symbols location and smoke-test list`.

## Task 5: Verification and PR

- [ ] `git diff` confirms only `android/app/build.gradle`,
  `android/app/proguard-rules.pro`, `.github/workflows/ci.yml`, and
  `docs/release/RELEASE_CHECKLIST.md` changed. No `lib/`, no schema, no
  signing, no `--split-per-abi`.
- [ ] Push and open a PR. State explicitly in the description that CI green
  does not verify the shrunk binary runs correctly on a device, and name the
  three smoke-test flows from Task 4.
- [ ] Confirm all required CI checks pass, including the Android build itself
  succeeding under the new flags (a build failure here would mean a
  ProGuard/R8 misconfiguration, which is worth knowing before merge even
  though a successful build still is not device verification).
- [ ] Squash merge; verify post-merge main CI green.

## Task 6: Measure and record the real size difference

**Do not do this until Task 5's PR is merged and a tagged release exists.**

- [ ] After the next tag build completes, compare its APK/AAB sizes against
  `v1.8.0`'s baseline (82 MB / 73 MB) using `gh release view <tag> --json
  assets`.
- [ ] Record the actual before/after sizes with evidence in
  `docs/superpowers/status/current-roadmap.md`. Do not estimate or assume a
  percentage reduction — measure it.
- [ ] Remind the owner in that same update that device smoke-testing (Task 4's
  three flows) is still their action before distributing that release.

## Stop conditions

- A build failure under the new R8 flags: read the exact Gradle/R8 error
  before adding a keep rule. Do not add speculative `-keep` rules to make an
  error disappear without understanding what class it refers to.
- Any temptation to add `--split-per-abi`: stop, that was explicitly declined.
- Any temptation to touch `signingConfig`: stop, that is a separate,
  owner-only decision.
