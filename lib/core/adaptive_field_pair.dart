import 'package:flutter/material.dart';

import 'responsive_layout.dart';

/// Lays two form fields side by side when there is room, and stacks them
/// otherwise.
///
/// Paired fields previously used a bare `Row` of two `Expanded` children. On a
/// ~393dp phone that leaves about 148dp per field, which truncates labels such
/// as `Satuan Dasar (mis. tablet, kapsul)` (about 218dp). Stacking gives each
/// label the full dialog width instead of shortening the wording. See
/// docs/superpowers/specs/2026-08-13-narrow-screen-readability.md.
class AdaptiveFieldPair extends StatelessWidget {
  const AdaptiveFieldPair({
    super.key,
    required this.first,
    required this.second,
    this.spacing = 8,
  });

  final Widget first;
  final Widget second;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    // Reuses the shell's width tiers rather than inventing a new number, so
    // "wide enough for a sidebar" and "wide enough for paired fields" stay
    // consistent.
    final sideBySide =
        AppBreakpointWidth.fromWidth(MediaQuery.sizeOf(context).width)
            .usesSidebar;

    if (sideBySide) {
      return Row(
        children: [
          Expanded(child: first),
          SizedBox(width: spacing),
          Expanded(child: second),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        first,
        SizedBox(height: spacing),
        second,
      ],
    );
  }
}
