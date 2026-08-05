# Backup user-facing error states

## Problem

Backup and restore actions exposed raw exception text, including platform plugin
errors. The Google Drive screenshot showed `MissingPluginException` directly to
users.

## Scope

- Localize backup creation, restore, preview, and Google Drive result states.
- Map configuration, permission, and unknown Drive failures to actionable safe
  messages without exposing exception text.
- Keep detailed exception values in logs/tests only; do not change transport or
  OAuth behavior.

## Acceptance criteria

- No raw exception is rendered by BackupScreen.
- Missing plugin/configuration maps to desktop OAuth setup guidance.
- Permission failures explain how to retry authorization.
- Success and failure states are localized in Indonesian and English.

## Non-goals

- No real Google credentials or account access.
- No change to Drive scope or upload protocol.
