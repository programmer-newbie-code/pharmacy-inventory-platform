# Current Pharmacy Platform Roadmap

**Last updated:** 2026-08-12

**Verified main:** `fc30bd4` (`docs(roadmap): establish cross-agent handoff (#146)`)

**Verified main CI:** run `31555388676`, completed successfully

**Open PR at audit:** none

**Next increment:** Priority 1 professional brand/icon direction; owner visual
approval is required before asset integration. Confirmed receiving correctness
work may proceed independently while that decision is pending.

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
| Branch/PR/CI workflow | Shipped | `AGENT.md`; PR #145 and main run `31547201220` are green. Continue enforcing it. |
| Cross-agent handoff | Shipped | PR #146 added the canonical spec, plan, live status, and startup routing; main run `31555388676` is green. |
| Release automation | Partial | Signed `v*` tags create Windows/Android artifacts; final roadmap release remains pending. |

## Recently shipped evidence

| PR | Shipped outcome |
| --- | --- |
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
| 2 | Windows desktop modernization | Partial | Responsive shell/sidebar/breadcrumb implementation exists in `home_screen.dart`; visual and keyboard QA plus approved refinement remain. |
| 3 | Android mobile modernization | Partial | Bottom/More navigation exists; task-frequency, one-handed, high-frequency flow, real-device, and text-scale review remain. |
| 4 | Accessibility/localization/docs | Partial | ARB and accessibility foundations exist; affected-flow audit and published docs responsive verification remain. |
| 5 | Google Play readiness | Partial / externally blocked | Application ID and release CI exist; final identity/signing/store/policy package remains. Owner account verification and publication are external. |
| 6 | Critical correctness | Broken item confirmed | `purchase_receiving_screen.dart` uses `authSessionProvider?.id ?? 1` and hard-coded strings. Create focused child spec/plan after Priority 0. |

## Preserved shipped capabilities

Do not reimplement report/export parity, Drive missing-session recovery, backup
integrity, receipt recovery, shift supervisor review, negative-stock protection,
price safeguards, or scanner lifecycle handling without a reproduced gap in
current main.

## External and owner-only actions

- Approve subjective icon and Windows/Android visual directions.
- Complete Google Play identity/payment/contact verification and agreements.
- Decide package-ID/signing-key custody before irreversible publication setup.
- Select real testers and submit Play declarations/production access.
- Provide real OAuth account consent and physical Android/scanner/printer tests.
- Decide regulated report/retention policy, destructive migrations, and external costs.

## Superseded priorities

Historical plans or status entries that list procurement/cash export parity,
Drive silent-skip recovery, receipt recovery, or shift supervisor review as next
work are superseded by PRs #132, #141, #139, and #145 respectively. Their files
remain historical evidence, not an instruction to duplicate work.
