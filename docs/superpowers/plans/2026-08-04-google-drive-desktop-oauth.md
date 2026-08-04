# Google Drive Desktop OAuth Implementation Plan

1. Add failing authorizer-selection tests for Windows and Android plus missing
   desktop configuration.
2. Implement a Windows browser-loopback authorizer using existing
   `googleapis_auth/auth_io.dart` and `drive.file` scope. Configuration comes
   from `GOOGLE_DRIVE_DESKTOP_CLIENT_ID` and
   `GOOGLE_DRIVE_DESKTOP_CLIENT_SECRET` Dart defines.
3. Convert Drive UI failures to ARB-backed actionable messages; remove raw
   exception presentation.
4. Document Google Cloud setup and release build defines without committing
   credentials.
5. Verify focused tests, generated code, analyze, coverage, Windows build,
   required CI, merge, green main. Validate against real Google account only
   after OAuth credentials are supplied.
