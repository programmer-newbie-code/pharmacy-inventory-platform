# Current Pharmacy Platform Roadmap

**Last updated:** 2026-08-14

**Verified main:** `8fcab36` (`localize(users,reports): move strings to ARB (slice 6) (#177)`)

**Verified main CI:** run `31799560927`, completed successfully.

**Released:** `v1.8.1`, published 2026-08-14 from `9687724`. Tag pipeline run
`31789879886` passed every job including `create-release`. Artifacts attached:
`...-android-v1.8.1.apk`, `...-android-v1.8.1.aab`,
`...-windows-v1.8.1.msix`, `...-windows-v1.8.1.zip`.

**Android size measurement (Task 6 of the shrink/obfuscate plan, #172), measured not estimated:**

| Artifact | v1.8.0 | v1.8.1 | Change |
| --- | --- | --- | --- |
| APK | 86,415,778 B (82.41 MB) | 81,369,510 B (77.60 MB) | -4.81 MB (-5.8%) |
| AAB | 77,524,842 B (73.93 MB) | 72,661,232 B (69.30 MB) | -4.64 MB (-6.3%) |

R8 shrinking and obfuscation alone yield a modest ~6% reduction, not a dramatic
one. This is expected and was flagged in the spec: the larger size driver is
bundling all three CPU architectures (arm64, armv7, x86_64) in one APK, which
`--split-per-abi` would address but the owner explicitly declined to keep a
single universal APK for GitHub Releases distribution simplicity. Do not
reopen that decision without a new owner request; it is not a bug.

**⚠️ Owner action still outstanding:** device smoke-test of this build
(Google Drive sign-in, barcode scanning, database access) before wider
distribution, per `docs/release/RELEASE_CHECKLIST.md` section 4. Not
performed in the agent environment — no Android device or Flutter toolchain
exists here.

**Adaptive icon orbit-ring rotation bug fixed (#175):** the modern-launcher
adaptive icon (`android/app/src/main/res/drawable/ic_launcher_foreground.xml`,
introduced in #156) had its orbit-ring gap open at the top instead of on the
right like the master SVG, because the hand-transcribed arc path never
applied the master's `rotate(28 512 512)` transform. Legacy
`mipmap-*/ic_launcher.png` files were unaffected (script-generated from the
rotated master), so only devices using the adaptive-icon path (API 26+) ever
showed the defect. Fixed by recomputing the arc endpoints with the missing
rotation applied and verifying pixel-identical to the master SVG via headless
Chrome renders (no Flutter/Android toolchain available in this environment).
Confirmed via `git log`/full-repo sweep that no other hand-authored asset has
the same defect — every other icon file is script-generated or a direct copy
of the rotated master. **This will still need owner verification on a real
device/launcher** since it wasn't visually confirmed on an actual Android
home screen, only via rendered SVG/vector-drawable comparison.

**Open PR at audit:** none

**⚠️ Known bug, root cause confirmed, fix deferred (owner-only signing decision):**
Google Drive backup sign-in fails on Android after account selection (owner-
reported). Root cause: `android/app/build.gradle` signs release builds with
`signingConfigs.debug`, and CI never caches `~/.android/debug.keystore`, so
every CI-built APK gets a **different, random signing certificate**. Google's
`google_sign_in` Android OAuth client is matched by package name + SHA-1
fingerprint (`USER_GUIDE.md` section 6.2), so a shifting fingerprint can never
stay registered/matched, producing a native `DEVELOPER_ERROR`
(`ApiException: 10`) that the app's error mapping
(`lib/features/backup/backup_screen.dart` `_mapDriveError`) doesn't recognize,
surfacing as a generic "Google Drive encountered a problem" message. Confirmed
this is **not** a Google Play Console / Play App Signing issue — the app is
distributed via GitHub Release APK/AAB artifacts built directly in CI
(`.github/workflows/ci.yml` `create-release` job), with no Play Store upload
path at all, so whatever keystore signs the GitHub Release artifact is the one
that must be registered.

Fix requires: (1) generate a real release keystore, (2) store its credentials
as GitHub Actions secrets, (3) add a `signingConfigs.release` block to
`android/app/build.gradle` sourced from those secrets, (4) update the
`build-android` CI job to decode and sign with it, (5) **owner registers the
new keystore's stable SHA-1 with the Android OAuth client in Google Cloud
Console** (external, owner-only). This closes the existing "Decide
package-ID/signing-key custody" open item below rather than opening a new
one. Not started; owner indicated they will pursue this in a separate
agent/session.

**Separate, smaller finding (no owner blocker, not yet fixed):** the
"Konfigurasi Google Drive" button/dialog
(`lib/features/settings/drive_setup_dialog.dart`, launched from
`lib/features/backup/backup_screen.dart`) is dead UI on Android — it collects
a manual OAuth Client ID/Secret that only `DesktopGoogleAccountAuthorizer`
(Windows-only, selected via `Platform.isWindows` in
`lib/data/google_drive_backup_service.dart`) ever reads. Android always uses
`GoogleSignInAuthorizer`, which never touches `DriveCredentialStore`. The
button should be platform-gated to Windows only in `backup_screen.dart`
(around the `configureDriveBtn` widget) — do not remove the dialog/feature
entirely, since Windows dev/fork builds without the CI-embedded
`GOOGLE_DRIVE_DESKTOP_CLIENT_ID/_SECRET` still rely on it as a fallback.

**Next increment:** Localization sweep slice 7 (`data/receipt_pdf_service.dart`
+ `alerts` + `settings` + `main.dart`) per
`docs/superpowers/plans/2026-08-12-feature-localization-sweep.md`. Slice 6
(#177) also surfaced a blind spot in
`scripts/audit_hardcoded_strings.py` (it only matched literals on the same
line as a `Text(...)` call; fixed to catch multi-line calls too), which in
turn surfaced **16 additional violations in already-shipped areas** not yet
fixed: inventory 4, `data/receipt_pdf_service.dart` 4, pos 3, alerts 2,
`main.dart` 1, settings 1, home 1. These overlap with slice 7's remaining
scope but are more numerous than the plan's original slice-7 count (18) —
re-run `python3 scripts/audit_hardcoded_strings.py lib` at the start of slice
7 to get the current, accurate list rather than trusting the plan's original
table.

**Owner-reported narrow-screen readability fixed (#169):** on a Vivo V23e
(~393x873dp), form-field labels truncated to `...`, Katalog Inventaris product
names truncated, and the POS quantity dialog was undiscoverable (looked like a
label, not a control). All three are fixed and covered by a reusable
`test/support/layout_harness.dart` at 393x873. Three separate, pre-existing
overflow defects were found and deliberately **not** fixed in the same PR
(recorded in `docs/superpowers/plans/2026-08-13-narrow-screen-readability.md`'s
Known Issues): the add/edit product dialog and the POS quantity dialog each
overflow their own chrome at 2.0 text scale, and the whole `PosScreen`
overflows at 2.0 text scale independent of the cart tile. **Owner verification
on the Vivo V23e is still outstanding** - CI and the harness are the only
automated gate; no Flutter toolchain or device exists in the agent environment.

Everything else on the roadmap is blocked on
owner approval, a physical device, or a Play account.

**Versioning:** do not edit `pubspec.yaml`. CI derives the version from the tag
(`.github/workflows/ci.yml`, "Auto-Inject Dynamic Version"), as
`docs/release/RELEASE_CHECKLIST.md` requires. The historical
`chore: bump version` commits predate that automation.

This is the stable handoff file. Update it after every merged increment. Current
GitHub and implementation evidence overrides this file if it becomes stale.

## Status vocabulary

- **Shipped:** merged implementation and matching verification exist.
- **In progress:** an active branch or PR is delivering the item.
- **Partial:** usable implementation exists, but an approved criterion or matching
  verification is absent.
- **Missing:** no implementation evidence exists.
- **Broken:** current evidence reproduces a defect.
- **Externally blocked:** code work is complete or exhausted, but verification needs
  owner credentials, account action, hardware, or another external state.
- **Deferred:** intentionally excluded pending an approved product/legal decision.
- **Superseded:** replaced by newer implementation or product direction.

## Delivery state

| Item | Status | Evidence / next action |
| --- | --- | --- |
| Branch/PR/CI workflow | Shipped | `AGENT.md`; PR #160 and main run `31657666877` are green. Continue enforcing it. |
| Cross-agent handoff | Shipped | PR #146 added the canonical spec, plan, live status, and startup routing; main run `31555388676` is green. |
| Release automation | Shipped for this cycle | `v1.8.1` published 2026-08-14 from `9687724`; tag run `31789879886` green with `create-release` executed and four artifacts attached. Android artifacts are now R8-shrunk and obfuscated (#172). Version is tag-derived, so `pubspec.yaml` was not edited. **Manual Windows and Android smoke testing required by `docs/release/RELEASE_CHECKLIST.md` was not performed** (no Flutter toolchain or device in the agent environment) and remains an owner action before distributing the artifacts — this is now more important than for prior releases, since obfuscation can break native-plugin integration in ways invisible to `flutter test`. |

## Recently shipped evidence

| PR | Shipped outcome |
| --- | --- |
| #177 | Localization sweep slice 6 (`features/users` 10 strings, `features/reports` 4). Also fixed a multi-line blind spot in `scripts/audit_hardcoded_strings.py` (it only matched literals on the same line as a `Text(...)` call), which surfaced and fixed one additional in-scope defect in `reports_screen.dart` plus 16 out-of-scope violations in already-shipped areas, left for slice 7 (see "Next increment" above). Both-locale widget assertions added for every changed string; ARB parity verified (524 keys). |
| #175 | Fixed adaptive-icon (`ic_launcher_foreground.xml`) orbit-ring gap orientation, which had been hand-transcribed from the master SVG without its 28° rotation, making it visibly mismatched from all other branding surfaces on API 26+ launchers. Single-line diff; verified pixel-identical to the master SVG via headless-Chrome rendering (no device verification performed). |
| #172-#173 | Android release build shrink and obfuscation (`minifyEnabled`, `shrinkResources`, baseline ProGuard rules, `--obfuscate --split-debug-info`), debug symbols uploaded as a private CI artifact, then `v1.8.1` tagged and published. Measured (not estimated) size change: APK -5.8% (82.41→77.60 MB), AAB -6.3% (73.93→69.30 MB). `--split-per-abi` was proposed and explicitly declined by the owner; the remaining size is mostly the three bundled CPU architectures in one universal APK, a known and accepted trade-off. |
| #169 | Narrow-screen readability, owner-reported from a Vivo V23e (~393x873dp): form-field label truncation (`Satuan Dasar...`), Katalog Inventaris product-name truncation, and an undiscoverable POS quantity dialog. Added a reusable `test/support/layout_harness.dart`. Three pre-existing, unrelated overflow defects found and deliberately deferred (dialog chrome at 2.0 text scale x2, whole-`PosScreen` text-scale overflow) — recorded in the plan's Known Issues, not fixed in this PR. Owner verification on the Vivo V23e still outstanding. 280 tests, coverage 81.2%. |
| #164 | Localization slice 5 (patients, compounding). Review of the slice found the audit script reporting an area clean while a literal behind a ternary was still hard-coded; fixed the script's regex, localized the patient form title, and added the both-locale test the slice was missing. Dosage-form stored values (`puyer`, `kapsul`, `salep`, `sirup`) preserved. |
| #162-#163 | Localization slices 3 and 4 (inventory, pos). |
| #160-#161 | Localization slice 2 (suppliers) and roadmap record. |
| #156-#158 | PharmaLoka brand identity, roadmap record, and CI path filtering so documentation-only changes skip the Flutter matrix. |
| #160 | Localization sweep slice 2 (`features/suppliers`): extracted 53 hardcoded strings across `supplier_list_screen.dart`, `supplier_detail_screen.dart`, and `purchase_order_screen.dart` to ARB. Total codebase hardcoded strings reduced from 169 to 116. Main run `31657666877` is green. |
| #156 | PharmaLoka Option A (Loka Bloom) shipped as a canonical SVG with reproducible Windows, Android adaptive/legacy, web, docs, MSIX, and Play Store exports. Compact surfaces use `PharmaLoka`; descriptive surfaces use `PharmaLoka — Pharmacy Inventory Platform`; stable technical identities remain unchanged. Flutter 3.47 toolchain requirements are pinned (AGP 8.11.1, Kotlin 2.2.20). Main run `31654201784` is green. |
| #153-#154 | Localization sweep: spec, plan, and `scripts/audit_hardcoded_strings.py`, then slice 1 fixing all 23 strings that rendered Indonesian to English users. Total hardcoded strings 198 to 169. Drug-classification stored values pinned by test; `lib/data/` still imports no localization. |
| #150-#151 | Adaptive shell correctness. Restored logout/language/help/branding, which were unreachable in production because they lived in a `HomeScreen` `AppBar` that never rendered; deleted ~250 lines of unreachable shell; fixed the no-op sidebar Dashboard item, the split navigation model, and mobile selected-index; made the two-tier width split explicit; localized the last shell strings. 255 tests, coverage 80.8%. |
| #148 | Purchase receiving now requires an active session (no more `?? 1` fallback) and is fully localized (en/id). Closes the Priority 6 critical-correctness item from the modernization spec. |
| #147 | Roadmap evidence recorded for the cross-agent handoff increment. |
| #146 | Canonical cross-agent startup, umbrella spec, detailed roadmap, and live status. |
| #145 | Closed-shift administrator review and schema migration. |
| #143-#144 | Active-session attribution/localization for shift cash operations and roadmap evidence. |
| #141-#142 | Automatic Drive backup records missing OAuth session instead of silently skipping. |
| #139-#140 | Receipt save/print recovery and roadmap evidence. |
| #137-#138 | Receiving/audit attribution improvement and delivery audit status. |
| #136 | Backup checksum integrity and failed-restore logging. |
| #135 | Classic sales export audit parity. |
| #132-#134 | Procurement/cash export parity, scanner lifecycle, and roadmap refresh. |
| #125-#131 | Receipt/media, best-selling analytics/localization/export, and related CI fixes. |

## Active approved roadmap

| Priority | Workstream | Status | Current evidence / next action |
| --- | --- | --- | --- |
| 0 | Durable cross-agent context | Shipped | PR #146 merged; post-merge main run `31555388676` is green. |
| 1 | ProgrammerNewbie Studio branding and icon | Shipped | #156 delivered the owner-approved Option A canonical SVG, deterministic platform exports, adaptive Android icon, final size proof, and PharmaLoka naming hierarchy. Post-merge main run `31654201784` is green. |
| 2 | Windows desktop modernization | Correctness shipped (#151); visual refinement pending | Sidebar chrome now owns navigation and global actions, with tests at 1366x768, 1920x1080, and the 1023/1024 boundary, plus `Tab` traversal and 2.0 text scale. Remaining: collapsible sidebar, top context bar, density, theme tokens — all need rendered comparison and owner approval. |
| 3 | Android mobile modernization | Correctness shipped (#151); narrow-screen readability shipped (#169); flow review pending | Bottom bar and More sheet report selection correctly. #169 fixed owner-reported truncation in Katalog Inventaris and the add/edit product dialog, plus made the POS quantity dialog discoverable. Remaining: task-frequency, one-handed reach, high-frequency POS/scanner flow beyond the cart tile, real-device verification of #169 on the reporting Vivo V23e, and the three known 2.0-text-scale overflow defects #169 deferred (add/edit dialog chrome, POS quantity dialog chrome, whole-`PosScreen`). |
| 4 | Accessibility/localization/docs | In progress (slices 1-6 of 7 shipped) | #153 added the audit scan and sliced plan; #154 fixed the mixed-language defect; #160, #162, #163, #164, and #177 swept suppliers, inventory, pos, patients, compounding, users, and reports. Slice 7 (data/receipt_pdf_service.dart, alerts, settings, main.dart) remains, now with an expanded scope of 16+ strings after #177's audit-script fix surfaced previously-invisible violations — re-scan before starting. Screen-reader, contrast, focus, and text-scale auditing plus docs-site responsive verification remain separate concerns. |
| 5 | Google Play readiness | Partial / externally blocked | Application ID and release CI exist; final identity/signing/store/policy package remains. Owner account verification and publication are external. **Related, higher-priority finding:** the Android release build signs with the debug keystore (`android/app/build.gradle`), which breaks Google Sign-In for Drive backup because the signing SHA-1 changes every CI run — see the "Known bug" note near the top of this file. Resolving this is a prerequisite for stable Google Sign-In regardless of Play Store publication status. |
| 6 | Critical correctness | Shipped (this instance); monitor for new evidence | PR #148 fixed the `purchase_receiving_screen.dart` `authSessionProvider?.id ?? 1` fallback and localized the screen. No other confirmed critical-correctness item is open — reopen this priority only if new evidence reproduces a defect. |

## Preserved shipped capabilities

Do not reimplement report/export parity, Drive missing-session recovery, backup
integrity, receipt recovery, shift supervisor review, purchase-receiving
session/localization, shell global-action reachability, the single in-shell
navigation model, negative-stock protection, price safeguards, scanner
lifecycle handling, or the narrow-screen readability fixes in
`add_product_dialog.dart`/`edit_product_dialog.dart`/`product_list_screen.dart`/`pos_screen.dart`
without a reproduced gap in current main.

`test/support/layout_harness.dart` is the reusable tool for any further
narrow-screen work: `useSurface`, `expectNoOverflow`, `expectNotTruncated`
(plain `Text` only — do not point it at an `InputDecoration` label, see the
helper's own doc comment), and `textScaleBuilder`. Extend it rather than
reinventing per-screen measurement.

Drug-classification dropdown values (`Obat Bebas`, `Obat Bebas Terbatas`,
`Obat Keras`) and compounding dosage-form values (`puyer`, `kapsul`, `salep`,
`sirup`) are persisted. Only their labels are localized, and tests pin the
stored values. Do not "localize" the values.

`scripts/audit_hardcoded_strings.py` reporting zero for an area is necessary but
not sufficient evidence. It matches literals lexically, so anything it cannot see
is invisible to a slice's definition of done. It was corrected in #164 to see
literals behind a conditional (`cond ? 'A' : 'B'`, `x ?? 'B'`); interpolated
strings are still reported separately and are out of the current slices' scope.

The shell deliberately implements **two** width tiers, not three: tablet
portrait (600-1023px) shares the bottom bar with phones because there is no
evidence of tablet use. A test pins this so it is not mistaken for a bug. Do not
add a `NavigationRail` tier without confirmed tablet usage.

## External and owner-only actions

- Approve the later Windows/Android visual directions.
- Complete Google Play identity/payment/contact verification and agreements.
- Decide package-ID/signing-key custody before irreversible publication setup.
- Select real testers and submit Play declarations/production access.
- Provide real OAuth account consent and physical Android/scanner/printer tests.
- Decide regulated report/retention policy, destructive migrations, and external costs.

## Superseded priorities

Historical plans or status entries that list procurement/cash export parity,
Drive silent-skip recovery, receipt recovery, shift supervisor review, or the
purchase-receiving session/localization gap, or shell logout/navigation
correctness as next work are superseded by PRs #132, #141, #139, #145, #148,
and #151 respectively. Their files remain
historical evidence, not an instruction to duplicate work.
