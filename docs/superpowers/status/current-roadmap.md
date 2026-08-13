# Current Pharmacy Platform Roadmap

**Last updated:** 2026-08-13

**Verified main:** `74d7a8f` (`localize(patients, compounding): extract hardcoded user-facing strings to ARB (#164)`)

**Verified main CI:** run `31668625534`, completed successfully.

**Open PR at audit:** none

**Next increment:** Release `v1.8.0` per
`docs/superpowers/plans/2026-08-13-release-v1-8-0.md`. 40 commits sit on `main`
unreleased since the `v1.7.0` tag of 2026-08-09, including the #151 fix for
logout being unreachable. Localization slice 6 (`features/users` 10 strings,
`features/reports` 4) follows the release; 22 plain and 34 interpolated strings
remain and none are user-visible defects, since all are English-only in an
English build.

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
| Release automation | Partial; release pending | Signed `v*` tags build and publish Windows and Android artifacts. **40 commits were unreleased at `503ce3d`** (last tag `v1.7.0`, 2026-08-09). `v1.8.0` is the increment closing that gap. Manual Windows and Android smoke testing required by `docs/release/RELEASE_CHECKLIST.md` is **not** performed in the agent environment (no Flutter toolchain, no device) and remains an owner action before distributing artifacts. |

## Recently shipped evidence

| PR | Shipped outcome |
| --- | --- |
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
| 3 | Android mobile modernization | Correctness shipped (#151); flow review pending | Bottom bar and More sheet now report selection correctly and expose the global actions. Remaining: task-frequency, one-handed reach, high-frequency POS/scanner flow, and real-device text-scale review. |
| 4 | Accessibility/localization/docs | In progress (slices 1-5 of 7 shipped) | #153 added the audit scan and sliced plan; #154 fixed the mixed-language defect; #160, #162, #163, and #164 swept suppliers, inventory, pos, patients, and compounding. 22 hardcoded strings remain: users 10, reports 4, data 3, alerts 2, main 1, settings 1, home 1. Screen-reader, contrast, focus, and text-scale auditing plus docs-site responsive verification remain separate concerns. |
| 5 | Google Play readiness | Partial / externally blocked | Application ID and release CI exist; final identity/signing/store/policy package remains. Owner account verification and publication are external. |
| 6 | Critical correctness | Shipped (this instance); monitor for new evidence | PR #148 fixed the `purchase_receiving_screen.dart` `authSessionProvider?.id ?? 1` fallback and localized the screen. No other confirmed critical-correctness item is open — reopen this priority only if new evidence reproduces a defect. |

## Preserved shipped capabilities

Do not reimplement report/export parity, Drive missing-session recovery, backup
integrity, receipt recovery, shift supervisor review, purchase-receiving
session/localization, shell global-action reachability, the single in-shell
navigation model, negative-stock protection, price safeguards, or scanner
lifecycle handling without a reproduced gap in current main.

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
