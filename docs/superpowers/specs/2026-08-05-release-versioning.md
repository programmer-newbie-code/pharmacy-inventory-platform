# Release versioning

## Problem

PR artifact builds derived their version from the newest tag rather than the
checked-out `pubspec.yaml`, producing a stale in-app version.

## Acceptance criteria

- Tag builds use the tag version.
- Branch and PR builds use the checked-out pubspec version.
- Windows and Android use the same rule.
