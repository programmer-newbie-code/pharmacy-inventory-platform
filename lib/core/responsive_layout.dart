enum AppBreakpoint { phone, tablet, desktop }

extension AppBreakpointWidth on AppBreakpoint {
  static AppBreakpoint fromWidth(double width) {
    if (width < 600) return AppBreakpoint.phone;
    if (width < 1024) return AppBreakpoint.tablet;
    return AppBreakpoint.desktop;
  }
}
