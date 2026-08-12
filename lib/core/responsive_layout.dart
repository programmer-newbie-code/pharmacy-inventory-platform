enum AppBreakpoint { phone, tablet, desktop }

extension AppBreakpointWidth on AppBreakpoint {
  static AppBreakpoint fromWidth(double width) {
    if (width < 600) return AppBreakpoint.phone;
    if (width < 1024) return AppBreakpoint.tablet;
    return AppBreakpoint.desktop;
  }

  /// Whether the shell renders the persistent sidebar instead of bottom
  /// navigation.
  ///
  /// The shell deliberately implements two chrome tiers, not three: only
  /// `desktop` (>= 1024px) gets the sidebar. Tablet-portrait widths
  /// (600-1023px) share the bottom bar with phones, because there is no
  /// evidence of tablet use today and a third chrome variant would be
  /// speculative. Rotating a tablet to landscape crosses 1024px and promotes
  /// it to the sidebar. See
  /// docs/superpowers/specs/2026-08-12-adaptive-shell-correctness.md.
  bool get usesSidebar => this == AppBreakpoint.desktop;
}
