# Report export feedback

## Problem

The report screen exposes raw exception details and leaves export/loading states
partly hard-coded.

## Acceptance criteria

- All export and report-loading feedback is localized.
- Technical exception text is never rendered to users.
- Export progress, success path, and recoverable failure are explicit.

## Constraints

Keep existing export behavior and audit logging unchanged.
