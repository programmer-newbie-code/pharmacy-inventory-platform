import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/responsive_layout.dart';

void main() {
  test('selects the pharmacy layout breakpoint from screen width', () {
    expect(AppBreakpointWidth.fromWidth(479), AppBreakpoint.phone);
    expect(AppBreakpointWidth.fromWidth(800), AppBreakpoint.tablet);
    expect(AppBreakpointWidth.fromWidth(1200), AppBreakpoint.desktop);
  });
}
