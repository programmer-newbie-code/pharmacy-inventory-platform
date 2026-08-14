# Android Shrink and Obfuscate Release Builds

Child increment of the Android release-quality workstream. Not part of the
signing-key custody decision, which remains separate and owner-only.

## Evidence

Audited at commit `2f2f3e2`.

- `android/app/build.gradle`'s `release` block sets only `signingConfig`. No
  `minifyEnabled`, no `shrinkResources`, no `proguardFiles`. `minifyEnabled`
  defaults to `false`, so R8 never runs on this app's own code today.
- `.github/workflows/ci.yml`'s `flutter build apk` and `flutter build
  appbundle` steps pass no `--obfuscate`, no `--split-debug-info`, no
  `--split-per-abi`.
- No `android/app/proguard-rules.pro` file exists.
- The published `v1.8.0` release artifacts are **82 MB** (`.apk`) and
  **73 MB** (`.aab`) — verified via `gh release view v1.8.0 --json assets`.
- `pubspec.yaml` includes three plugins whose Android integration touches
  native or JNI code and are the most likely to need explicit shrinking
  awareness: `sqlite3_flutter_libs`, `mobile_scanner`, `google_sign_in`.
- `grep -rn "runtimeType.toString()\|runtimeType ==" lib/` returns nothing, so
  no code depends on human-readable class/type names at runtime — the
  documented obfuscation caveat in Flutter's own deployment guide does not
  apply to this codebase.
- `flutter test` runs Dart in a test harness, not through the Android R8/AOT
  pipeline, so CI going green after this change proves the build compiles and
  the existing test suite still passes; it does **not** prove a shrunk release
  binary runs correctly on a device. This is stated explicitly rather than
  implied.

## Goal

Reduce the distributed Android APK/AAB size and raise the bar against casual
reverse engineering, without changing signing, without splitting the
distributed APK into multiple files, and without touching the Windows build.

## Scope

- `android/app/build.gradle`: enable `minifyEnabled` and `shrinkResources` in
  the `release` build type, referencing a new `proguard-rules.pro`.
- `android/app/proguard-rules.pro`: a baseline keep-rule file. Flutter plugins
  are expected to ship their own consumer ProGuard rules bundled in their AAR,
  which R8 merges automatically; this file adds only what Flutter's own
  deployment guidance recommends and does not attempt to write rules for
  third-party plugin internals that cannot be verified without a device.
- `.github/workflows/ci.yml`: add `--obfuscate
  --split-debug-info=build/symbols/<job>` to both the `flutter build apk` and
  `flutter build appbundle` steps.
- Upload `build/symbols/` as a private, workflow-run-scoped CI artifact with a
  90-day retention. It must never be attached to the public GitHub Release.
- A short note in `docs/release/RELEASE_CHECKLIST.md` recording where the
  symbols artifact lives and why it is needed.

## Explicitly out of scope

- **APK splitting.** The owner chose to keep a single universal APK for
  simplest GitHub Releases distribution, even though `--split-per-abi` would
  shrink each resulting file further. The AAB is unaffected by this decision:
  Google Play's own Dynamic Delivery already serves per-device splits from a
  single uploaded AAB, so the AAB's internal structure needs no change here
  regardless of the APK decision.
- **Release signing.** `signingConfig signingConfigs.debug` is unchanged.
  Fixing it requires a real keystore that only the owner can hold custody of,
  per `AGENT.md`'s signing-key custody rule, and is a separate decision.
- **The Windows build.** Windows release builds have no R8/shrinking
  equivalent, and native-binary obfuscation for a desktop executable is a
  materially different, larger problem than Dart obfuscation. Not touched.
- Rewriting or auditing plugin-internal ProGuard rules. Trusted to the
  plugins' own bundled consumer rules unless a reproduced crash proves
  otherwise.

## Required behavior

- Release APK and AAB builds run through R8 with shrinking and resource
  removal enabled.
- Dart symbol names in the release binary are obfuscated; a matching symbols
  artifact is produced and stored privately per build.
- The app's existing automated test suite continues to pass unchanged — this
  change touches build configuration only, not `lib/`.
- No schema, pricing, permission, or business-logic file changes.

## Acceptance criteria

1. `android/app/build.gradle`'s release build type sets `minifyEnabled true`
   and `shrinkResources true`, and references `proguard-rules.pro`.
2. CI's Android build step passes `--obfuscate` and `--split-debug-info`; the
   resulting `build/symbols` directory is uploaded as a workflow artifact, not
   attached to the GitHub Release.
3. CI's Windows build step is unchanged.
4. `android/app/build.gradle`'s `signingConfig` line is unchanged.
5. No `--split-per-abi` flag is added; the release APK remains a single file.
6. `flutter analyze` and the full test suite remain green; CI-filtered
   coverage stays at or above 80 percent.
7. The PR description states plainly that green CI does not verify the shrunk
   binary runs correctly on a device, and names the specific flows (Drive
   sign-in, barcode scanning, database access) the owner should smoke-test
   before trusting the release build.
8. Post-merge, the released artifact sizes are compared against `v1.8.0`'s 82
   MB / 73 MB baseline and the difference is recorded with evidence, not
   assumed.

## Migration and rollback

No schema or data change. Rollback is reverting the `build.gradle` block and
the two CI flags — a same-day, code-only revert with no data-migration
concern.

## Risks and controls

- **A native/JNI-dependent plugin crashes only in the shrunk release build.**
  This class of failure is invisible to `flutter test`, which runs in a debug
  test harness untouched by R8. The three plugins with the highest risk
  (`sqlite3_flutter_libs`, `mobile_scanner`, `google_sign_in`) are named
  explicitly as the owner's smoke-test checklist before distributing the next
  release. CI green is not claimed as proof the release binary works.
- **Losing the symbols artifact makes a future crash report undecodable.**
  Stored per build with 90-day retention; if a release needs longer-term crash
  support, re-run the build from its tagged commit to regenerate matching
  symbols rather than relying on artifact retention indefinitely.
- **Obfuscation breaking reflection-dependent code.** Checked: no
  `runtimeType.toString()` or `runtimeType ==` matching exists in `lib/`, so
  this documented Flutter caveat does not apply here.
- **Confusing size reduction with actual security.** Recorded plainly:
  obfuscation renames symbols; it does not encrypt resources, does not prevent
  decompilation, and does not protect any secret that should not be in the
  binary in the first place. This is a increase in reverse-engineering
  *effort*, not a guarantee.

## Verification strategy

CI is the only automated gate available in the implementation environment: no
Android device or physical hardware exists to install and smoke-test the
shrunk release binary. Acceptance criterion 7 makes this limitation explicit
in the PR rather than implying a green build was device-verified. Real
verification is an owner action after merge, per the risks section above.
