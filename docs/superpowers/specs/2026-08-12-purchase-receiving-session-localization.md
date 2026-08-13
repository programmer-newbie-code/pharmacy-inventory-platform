# Purchase Receiving Session and Localization

## Evidence

Current `PurchaseReceivingScreen` forwards
`authSessionProvider?.id ?? 1` to `processReceiving`. A signed-out or expired
session can therefore create stock, receiving, and audit records attributed to
the seed administrator. PR #137 intentionally retained this fallback and did
not localize the receiving workflow.

The screen also contains hard-coded English for its title, actions, supplier
summary, line details, fields, discrepancy validation, empty state, success,
and failure messages.

## Required behavior

- Completing a receipt requires an active `authSessionProvider` user.
- When no session exists, show the existing localized `sessionRequired`
  message and create no receiving, stock-batch, purchase-order, or audit
  mutation.
- When authenticated, persist the active user's id as `receivedBy` and retain
  current full and partial receiving reconciliation.
- Localize all user-visible strings owned by
  `PurchaseReceivingScreen` in English and Indonesian ARB files.
- Show a safe localized failure message without exposing raw exception text.
- Keep current responsive structure, field behavior, and repository contract.

## Acceptance criteria

1. A widget test proves a signed-out completion attempt creates no receiving
   record and leaves the purchase order open.
2. Existing authenticated attribution coverage remains green.
3. Widget coverage proves representative Indonesian title, action, field,
   validation, and empty/success text comes from ARB resources.
4. Generated localization sources are clean after `flutter gen-l10n`.
5. Analyzer, focused/full tests, filtered coverage, available builds, PR CI,
   and post-merge main CI pass.

## Scope boundaries

No schema migration, permission redesign, supplier-screen localization,
inventory-math change, or historical data repair. Session expiry navigation is
handled by the existing application shell; this screen only blocks unsafe
mutation and explains why.

## Risk and rollback

Risk is limited to receiving-screen copy and the now-blocked signed-out path.
Rollback is code-only. No stored data format changes.
