# Barcode Camera Reliability Implementation Plan

1. Add a failing test that verifies Android camera permission declaration.
2. Add failing widget tests for localized camera failure/retry presentation.
3. Declare `android.permission.CAMERA`, implement scanner lifecycle ownership,
   map scanner errors to ARB-backed recovery UI, and hide the unsupported
   Windows camera action with localized keyboard-wedge guidance.
4. Run focused scanner tests, full Flutter analysis/tests, Windows build, and
   Android build when SDK is available.
5. Create a signed PR, wait every required CI check, squash merge, and verify
   `main` CI. Physical Android validation remains required before release.

## Follow-up increment: lifecycle stop coverage (2026-08-11)

1. Add a focused regression test that guards the lifecycle contract when the
   plugin controller cannot be instantiated in a host widget test.
2. Stop the initialized controller for every non-resumed lifecycle state and
   preserve the existing resume behavior.
3. Run scanner-focused tests, full analyzer/tests/coverage, Windows build, and
   Android build when the local SDK is available; then use the normal signed
   PR, green CI, squash merge, and green-main process.
