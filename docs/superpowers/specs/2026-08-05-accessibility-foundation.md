# Accessibility foundation

## Problem

High-frequency controls rely on icons without consistently exposing an
accessible name. The desktop navigation semantic contract also needs a
regression test.

## Scope

Add accessible names to the highest-frequency inventory and POS actions and
protect the desktop navigation contract with a widget test.

## Acceptance criteria

- Desktop navigation retains an accessible name.
- Refreshing inventory exposes a localized accessible name.
- Adding a product to the POS cart exposes its localized product name.
- Both English and Indonesian ARB catalogs provide the new strings.
