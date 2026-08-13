# Barcode Camera Reliability

## Problem

Android product-entry scanner opens a blank preview. The manifest does not
declare `android.permission.CAMERA`. The supplied scanner controller also
disables `mobile_scanner`'s built-in lifecycle handling, while the current error
view exposes only a technical error code and no recovery action.

**Follow-up audit (2026-08-11):** permission, retry, Android declaration, and
Windows keyboard-wedge guidance are now implemented. `CameraScannerDialog`
still returns without stopping its controller for `hidden` and `paused` app
lifecycle events, so a backgrounded Android scanner can retain camera access.

## Scope

- Declare Android camera permission.
- Keep the scanner camera lifecycle aligned with application lifecycle.
- Show localized, actionable permission/camera failure states with retry.
- On Windows, hide the unsupported camera action and explain the supported
  USB/Bluetooth keyboard-wedge workflow.

## Non-goals

- A true Windows webcam scanner backend; `mobile_scanner` does not support
  Windows and keyboard-wedge scanning remains the supported desktop path.
- Replacing the barcode recognition engine.

## Acceptance criteria

- Android package declares camera permission and scanner can request it.
- Leaving the app stops the scanner; returning resumes it when initialized.
- Permission and camera failures never leave an empty preview and provide retry
  or close actions without raw implementation details.
- Existing scan callback still returns a non-empty barcode exactly once.
- Indonesian and English copy are in ARB resources.

The remaining follow-up must stop the initialized controller for `inactive`,
`hidden`, `paused`, and `detached`, then resume it only on `resumed`.

## Manual verification

- On an Android physical device, accept camera permission and scan a product
  barcode.
- Deny permission, verify recovery message, then retry after granting it.
- Background and resume the app while the dialog is open.
