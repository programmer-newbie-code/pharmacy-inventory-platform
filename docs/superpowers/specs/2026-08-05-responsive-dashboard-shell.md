# Responsive pharmacy dashboard shell

## Problem

The current dashboard uses one card grid for every viewport. It is usable on a
phone, but Windows users need persistent orientation, fast module switching, and
denser workspace navigation.

## Users and scope

- Windows administrators, inventory staff, and cashiers get a branded fixed
  sidebar with grouped, permission-aware destinations, a top app bar, and a
  breadcrumb workspace marker.
- Android keeps the touch-first dashboard and gets a bottom navigation bar for
  the most common destinations.
- Both platforms keep the same domain screens, role checks, translations, and
  deep-link/navigation behavior.

## Non-goals

- No new business rules, permissions, or server synchronization.
- No separate Windows and Android feature implementations.

## Acceptance criteria

- At widths >= 1024, the dashboard renders the sidebar and hides bottom
  navigation; unauthorized destinations are not shown in the sidebar.
- At phone widths, the dashboard renders bottom navigation and has no sidebar.
- Sidebar and bottom-navigation actions have semantic labels and route to the
  existing feature screens.
- The branded icon is visible in the Windows sidebar and is bundled as an app
  asset.
- Wide and phone widget tests pass without overflow or framework exceptions.

## Manual verification

Run the Windows build at 1366x768 and 1920x1080; verify sidebar scrolling,
keyboard focus, role-specific menu visibility, and module navigation. Run the
Android build at 360x640; verify bottom navigation and one-handed reachability.
