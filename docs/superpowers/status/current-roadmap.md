# Current Pharmacy Platform Roadmap

**Last updated:** 2026-08-12

**Verified main:** `3dee9e9` (`fix(home): make the shell correct at both width tiers (#151)`)

**Verified main CI:** run `31572670200`, completed successfully

**Open PR at audit:** none

**Next increment:** Priority 2/3 visual modernization (collapsible sidebar, top
context bar, density, theme tokens) is the remaining shell work, and it needs
rendered before/after comparison plus owner approval before implementation.
Priority 1 brand/icon still blocks on owner visual selection. Shell
*correctness* is now closed by #151.

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
| Branch/PR/CI workflow | Shipped | `AGENT.md`; PR #151 and main run `31572670200` are green. Continue enforcing it. |
| Cross-agent handoff | Shipped | PR #146 added the canonical spec, plan, live status, and startup routing; main run `31555388676` is green. |
| Release automation | Partial | Signed `v*` tags create Windows/Android artifacts; final roadmap release remains pending. |

## Recently shipped evidence

| PR | Shipped outcome |
| --- | --- |
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
| 1 | ProgrammerNewbie Studio branding and icon | Partial / externally blocked | Platform icon files exist. Owner selection among the proposed visual directions is required before concept rendering and integration. |
| 2 | Windows desktop modernization | Correctness shipped (#151); visual refinement pending | Sidebar chrome now owns navigation and global actions, with tests at 1366x768, 1920x1080, and the 1023/1024 boundary, plus `Tab` traversal and 2.0 text scale. Remaining: collapsible sidebar, top context bar, density, theme tokens — all need rendered comparison and owner approval. |
| 3 | Android mobile modernization | Correctness shipped (#151); flow review pending | Bottom bar and More sheet now report selection correctly and expose the global actions. Remaining: task-frequency, one-handed reach, high-frequency POS/scanner flow, and real-device text-scale review. |
| 4 | Accessibility/localization/docs | Partial | ARB and accessibility foundations exist; affected-flow audit and published docs responsive verification remain. |
| 5 | Google Play readiness | Partial / externally blocked | Application ID and release CI exist; final identity/signing/store/policy package remains. Owner account verification and publication are external. |
| 6 | Critical correctness | Shipped (this instance); monitor for new evidence | PR #148 fixed the `purchase_receiving_screen.dart` `authSessionProvider?.id ?? 1` fallback and localized the screen. No other confirmed critical-correctness item is open — reopen this priority only if new evidence reproduces a defect. |

## Preserved shipped capabilities

Do not reimplement report/export parity, Drive missing-session recovery, backup
integrity, receipt recovery, shift supervisor review, purchase-receiving
session/localization, shell global-action reachability, the single in-shell
navigation model, negative-stock protection, price safeguards, or scanner
lifecycle handling without a reproduced gap in current main.

The shell deliberately implements **two** width tiers, not three: tablet
portrait (600-1023px) shares the bottom bar with phones because there is no
evidence of tablet use. A test pins this so it is not mistaken for a bug. Do not
add a `NavigationRail` tier without confirmed tablet usage.

## External and owner-only actions

- Approve subjective icon and Windows/Android visual directions.
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
