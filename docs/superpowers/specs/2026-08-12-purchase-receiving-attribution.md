# Purchase receiving actor attribution

## Evidence

`PurchaseReceivingScreen` calls `processReceiving` with a hard-coded
`receivedByUserId: 1`, so receiving and audit records can falsely attribute a
real user's inventory receipt to the seed administrator.

## Scope and acceptance

- Read the authenticated user from `authSessionProvider` and forward its id.
- Preserve the established id-1 fallback for signed-out test/bootstrap flows.
- Add a widget regression test proving an authenticated user is used.
- No schema, migration, inventory math, permissions, or UI redesign change.

## Platform, rollback, and risks

This is platform-independent Dart behavior. Revert is code-only; historical
records remain unchanged. The fallback retains current bootstrap compatibility.
