# Accessibility workflow guards

## Scope

Keep desktop workspace navigation and mobile primary navigation usable through
semantics and keyboard/touch interaction. Guard the responsive shell against
regressions at common Windows and phone widths.

## Acceptance criteria

- Desktop navigation exposes readable semantic labels and 48dp-or-larger targets.
- Desktop navigation can receive keyboard focus and activate with Enter.
- The mobile shell remains visible at phone width and primary destinations remain
  labelled.
- Widget coverage exercises these behaviors at 1366x768 and 390x844.

## Non-goals

Physical-device screen-reader and reduced-motion validation remain manual checks.
