# POS Shift Session Attribution and Localization

## Current-state evidence

`ShiftManagementScreen` reads, opens, and closes shifts for literal user ID
`1`; `CashMovementDialog` records movements as the active user or falls back to
`1`. Both screens also contain hard-coded English and Indonesian operational
strings even though the application has ARB localization and an authenticated
session provider. This risks attributing financial operations to the wrong user
and yields inconsistent language selection.

## Scope

- Attribute shift reads, opens, closes, and cash movements to the active
  authenticated user only.
- Refuse a financial operation safely when no session exists; never substitute
  a default user.
- Move all newly touched operational UI, validation, and feedback strings to
  English and Indonesian ARB resources.
- Preserve existing repository-side reconciliation, discrepancy validation,
  audit behavior, and layout.

## Non-goals

- Changing role policy, reconciliation formulae, shift-history visibility,
  database schema, or supervisor workflow.
- Reworking visual layout or introducing new financial fields.

## Acceptance criteria

1. No POS shift or cash movement write uses `?? 1` or a literal cashier ID.
2. A missing session shows a localized safe message and creates no record.
3. The logged-in user ID is passed to shift repository operations and cash
   movement attribution.
4. English and Indonesian locale tests prove the primary shift dialogs use
   localized labels and feedback.
5. Existing reconciliation and cash-movement tests continue to pass.

## Platform, data, and release impact

This is shared Flutter behavior for Windows and Android. No migration or data
rollback is needed; existing records are unchanged. The only behavioral change
is preventing an unauthenticated financial write. Release impact is normal
Windows/Android build verification.

## Risks and deferred decisions

The app should normally route unauthenticated users to login, but a safe guard
remains necessary for provider overrides, session expiry, and tests. Supervisor
approval policy and real printer/device QA stay separate increments.
