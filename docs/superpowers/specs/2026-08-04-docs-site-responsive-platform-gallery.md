# Docs Site Responsive Platform Gallery

## Problem

The GitHub Pages multi-platform screenshot table renders both full-size images in
one Markdown table row. At desktop widths the Android screenshot overflows and
visually overlaps the page; at narrow widths both screenshots are unreadable.

## Users

Prospective users comparing Windows and Android workflows, and existing users
looking for the correct download target.

## Scope

- Replace the screenshot Markdown table with semantic gallery markup.
- Present Windows and Android screenshots side by side when space permits and
  one per row on small screens.
- Constrain image size without cropping screenshots or causing horizontal
  overflow.

## Non-goals

- Redesign the GitHub Pages theme or application UI.
- Generate new screenshots.

## Acceptance criteria

- At 1280px the two platform cards fit inside the documentation content area,
  with neither image overlapping or overflowing.
- At 360px the cards stack and each image remains fully visible.
- Images have descriptive alternative text and visible labels.
- The page still builds with Jekyll/GitHub Pages.

## Manual verification

- Inspect the rendered page at desktop and phone widths.
- Confirm both screenshot assets load and retain their full aspect ratio.
