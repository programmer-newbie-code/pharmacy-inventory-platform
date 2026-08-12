# PharmaLoka Professional Branding and Icon

**Approved:** 2026-08-13

## Decision

The product display name is **PharmaLoka** and the publisher brand is
**ProgrammerNewbie Studio**. Package identifiers, executable names, repository
names, and database paths remain unchanged to preserve upgrades and external
configuration.

The owner approved the evolutionary **Loka Bloom** direction (option A):

- retain the current icon's rounded-square container, white four-lobed pharmacy
  bloom, and green leaf so existing users recognize it;
- replace the dull teal with a premium midnight-navy/deep-blue background;
- add one bright turquoise orbit with a single clean break to express “Loka” as
  place, locality, and connected world;
- remove the concept's dots and all other small decoration;
- use no app name, initials, letters, or words inside the icon.

## Vector geometry and palette

The canonical artwork is a hand-authored SVG with a `0 0 1024 1024` view box.
It must remain crisp and recognizable at 16 px.

| Element | Requirement |
| --- | --- |
| Container | Rounded square, 208 px corner radius |
| Background | Controlled linear gradient from `#081A33` to `#123C69` |
| Orbit | 48 px rounded stroke, turquoise `#2DD4BF` to sky `#38BDF8`, one gap, no dots |
| Pharmacy bloom | Solid white, optically centered, four rounded lobes |
| Leaf | Emerald `#22C55E` to `#16A34A`, one white vein |
| Effects | No shadow, glow, bevel, texture, outline clutter, or raster-only detail |

A square master and a full-bleed maskable/adaptive variant share identical
inner geometry. Gradients must be defined in SVG and degrade to a strong
solid-color silhouette.

## Asset matrix

| Consumer | Required artifact |
| --- | --- |
| Canonical | `assets/branding/app_icon.svg` |
| Maskable source | `assets/branding/app_icon_maskable.svg` |
| Flutter/MSIX | `assets/branding/app_icon.png`, 1024x1024 |
| Play Console | `assets/branding/play_store_icon.png`, opaque 512x512 |
| Windows | `windows/runner/resources/app_icon.ico`, 16/24/32/48/64/128/256 px |
| Android legacy | `mipmap-*/ic_launcher.png`, 48/72/96/144/192 px |
| Android adaptive | `mipmap-anydpi-v26/ic_launcher.xml`, vector foreground, solid background |
| Web | favicon plus regular/maskable 192 and 512 px icons |
| Documentation | SVG mark and 32 px favicon under `docs_site/assets/images/` |

Generated raster assets must come from the SVG source, use high-quality
downsampling, and keep opaque corners where platform masking requires them.

## Display-brand integration

Update user-visible product names in Flutter localization, Android app label,
Windows window/version metadata, MSIX display metadata, web manifest/title,
README, installation/user guides, and published GitHub Pages. Use
“PharmaLoka” for the product and “ProgrammerNewbie Studio” for the publisher.

Do not rename:

- Dart package `pharmacy_inventory_platform`;
- Android application ID or namespace;
- MSIX identity name;
- Windows executable or CMake binary;
- OAuth client configuration;
- repository URL.

Those identifiers affect upgrades, imports, OAuth, or distribution and require
a separate irreversible migration decision.

## Acceptance criteria

1. The SVG contains only deterministic vector geometry and the approved
   palette; it contains no text.
2. Raster and ICO files exist at every required size and pass automated header
   checks.
3. Android 26+ uses adaptive icon resources; legacy Android and Windows builds
   continue to use valid fallback assets.
4. User-visible product surfaces say PharmaLoka and applicable publisher
   surfaces say ProgrammerNewbie Studio.
5. Package/application/identity/executable identifiers remain byte-for-byte
   unchanged.
6. A visual sheet shows the final icon at 1024, 64, 32, and 16 px on light and
   dark backgrounds for owner review before merge.
7. Analyzer, full tests, filtered coverage, Windows build, PR Android/Windows
   builds, and post-merge main CI pass.

## Risks and rollback

Small-size orbit or leaf detail can blur; the 16/32 px proof is the acceptance
gate. Adaptive masks can crop unsafe artwork; keep all foreground meaning
inside the central safe zone. Rollback replaces display metadata and assets
only; no stored data or schema changes.
