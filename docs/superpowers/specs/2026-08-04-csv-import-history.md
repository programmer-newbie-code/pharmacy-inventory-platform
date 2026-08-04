# CSV import history

Date: 2026-08-04

## Problem

Inventory staff can preview and commit a CSV import, but there is no durable
record of which file was used, how many rows were accepted, or why rows were
skipped. This makes troubleshooting and audit review difficult.

## Scope

- Persist one immutable summary row for every completed import attempt.
- Record source filename, timestamp, initiating username, row totals, accepted
  rows, rejected rows, and a bounded error summary.
- Keep product writes and the history row in one transaction so a failed import
  cannot claim success.
- Expose a repository query for newest-first history; a follow-up UI increment
  renders it from the inventory workflow with the selected filename and
  initiating username.

## Non-goals

- Do not retain uploaded CSV contents or passwords.
- Do not change duplicate or validation policy.
- Do not make import history a substitute for the existing audit log.

## Acceptance criteria

- Schema migration creates the history table for existing installations.
- A successful import writes exactly one summary with accepted/rejected counts.
- An unexpected transactional failure writes a failed summary with zero
  accepted rows and an actionable error message, without products persisted.
- History queries are newest-first and covered by data tests.
- Backup/restore includes history rows before the workstream is considered
  complete.
- The inventory screen exposes a localized history action that shows source,
  actor, timestamp, row counts, and bounded failure details.

## Manual verification

Import a file containing valid, duplicate, and malformed rows on Windows and
Android; confirm the outcome is visible after reopening the screen and survives
a local backup/restore.
