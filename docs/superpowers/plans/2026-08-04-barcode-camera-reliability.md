# Barcode Camera Reliability Implementation Plan

1. Add a failing test that verifies Android camera permission declaration.
2. Add failing widget tests for localized camera failure/retry presentation.
3. Declare `android.permission.CAMERA`, implement scanner lifecycle ownership,
   and map scanner errors to ARB-backed recovery UI.
4. Run focused scanner tests, full Flutter analysis/tests, Windows build, and
   Android build when SDK is available.
5. Create a signed PR, wait every required CI check, squash merge, and verify
   `main` CI. Physical Android validation remains required before release.
