# Docs Site Responsive Platform Gallery Implementation Plan

## Goal

Make platform screenshots readable and non-overlapping on GitHub Pages.

## PR-sized tasks

1. Add a gallery component style in `docs_site/_layouts/default.html` with a
   two-column desktop grid, one-column narrow layout, bounded images, and
   keyboard-visible focus for linked images.
2. Replace the Markdown image table in `docs_site/index.md` with two labelled
   `figure` elements using the existing assets and descriptive alternative text.
3. Verify generated HTML/layout locally when Jekyll is available; otherwise
   inspect source dimensions and rely on GitHub Pages deployment verification.
4. Run whitespace/diff checks, commit signed changes, open PR, wait full CI,
   squash merge, and verify green `main` Pages/CI state.

## Rollback

Revert the single documentation PR. No application data or binary behavior is
affected.
