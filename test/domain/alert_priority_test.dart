import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/domain/alert_priority.dart';

void main() {
  group('AlertPriority', () {
    test('expired has highest priority', () {
      expect(AlertPriority.expired.priority, lessThan(AlertPriority.expiring.priority));
    });

    test('expiring is critical', () {
      expect(AlertPriority.expiring.isCritical, true);
    });

    test('low stock is not critical', () {
      expect(AlertPriority.lowStock.isCritical, false);
    });

    test('openShift is lowest priority', () {
      expect(AlertPriority.openShift.priority, greaterThan(AlertPriority.lowStock.priority));
    });

    test('values are in correct order', () {
      const values = AlertPriority.values;
      for (int i = 1; i < values.length; i++) {
        expect(values[i].priority, greaterThan(values[i - 1].priority));
      }
    });
  });
}
