# Implementation plan: purchase receiving actor attribution

1. Import the existing auth-session provider in the receiving screen.
2. Replace the constant receiver id with the session user id and existing
   bootstrap fallback.
3. Extend the receiving widget test to verify the persisted receipt/audit actor.
4. Run formatting, analyzer, focused/full tests, coverage, builds, signed PR,
   all CI gates, merge, and main-CI verification.
