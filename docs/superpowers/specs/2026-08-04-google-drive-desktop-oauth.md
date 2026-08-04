# Google Drive Desktop OAuth

## Problem

Windows invokes `google_sign_in`, which has no Windows plugin implementation.
The user sees `MissingPluginException` instead of a Drive backup flow. Android
uses Google Sign-In, while Windows requires an installed-application OAuth
authorization-code flow with browser loopback redirect.

## Scope

- Select Android Google Sign-In and Windows desktop OAuth at runtime.
- Read Windows desktop OAuth client configuration from build-time defines; never
  commit credentials.
- Open the system browser, complete loopback consent, upload with `drive.file`,
  and expose safe, localized configuration/auth/upload failures.

## External decision

Real Windows verification needs an enabled Drive API and a Google Cloud Desktop
OAuth client ID/secret supplied at build time. No production credential may be
added to source control.

## Acceptance criteria

- Windows never calls `google_sign_in` and never exposes MissingPluginException.
- Missing desktop configuration explains the exact next step without secrets.
- Android retains supported Google Sign-In flow.
- Tests use injected authorizers; no mock-success production path.
