# Adaptive workspace navigation

## Problem

Desktop module navigation pushes a new full-screen route over the dashboard,
hiding the sidebar and adding an unnecessary Back button. Mobile navigation
always marks Home selected and routes its More destination to Alerts.

## Scope

- Desktop uses a full-height persistent sidebar and swaps top-level workspace
  content without a Back action.
- Mobile uses persistent Home, POS, Products, and a genuine More menu.
- Back remains only for drill-down routes inside a selected workspace.
- Navigation respects role visibility, localization, semantics, and breakpoints.

## Acceptance criteria

- Selecting a desktop module retains the sidebar and updates its selected state.
- Selecting POS or Products on mobile retains the bottom navigation.
- More opens a menu rather than silently opening Alerts.
- Desktop and mobile navigation behavior is regression-tested.
