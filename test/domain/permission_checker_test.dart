import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/domain/permission_checker.dart';

void main() {
  final checker = PermissionChecker();

  test('admin has full access to every resource except audit log (view-only)', () {
    for (final resource in Resource.values.where((r) => r != Resource.auditLog)) {
      expect(checker.accessLevel(Role.admin, resource), AccessLevel.full,
          reason: 'admin should have full access to $resource');
    }
    expect(checker.accessLevel(Role.admin, Resource.auditLog), AccessLevel.view);
  });

  test('inventory can manage products/batches and storage locations, view-only elsewhere', () {
    expect(checker.accessLevel(Role.inventory, Resource.productsAndBatches), AccessLevel.full);
    expect(checker.accessLevel(Role.inventory, Resource.storageLocations), AccessLevel.full);
    expect(checker.accessLevel(Role.inventory, Resource.salesPos), AccessLevel.view);
    expect(checker.accessLevel(Role.inventory, Resource.reports), AccessLevel.view);
    expect(checker.accessLevel(Role.inventory, Resource.auditLog), AccessLevel.none);
    expect(checker.accessLevel(Role.inventory, Resource.users), AccessLevel.none);
  });

  test('kasir can only view catalog data, create sales, and view own reports', () {
    expect(checker.accessLevel(Role.kasir, Resource.productsAndBatches), AccessLevel.view);
    expect(checker.accessLevel(Role.kasir, Resource.storageLocations), AccessLevel.view);
    expect(checker.accessLevel(Role.kasir, Resource.salesPos), AccessLevel.create);
    expect(checker.accessLevel(Role.kasir, Resource.reports), AccessLevel.viewOwn);
    expect(checker.accessLevel(Role.kasir, Resource.auditLog), AccessLevel.none);
    expect(checker.accessLevel(Role.kasir, Resource.users), AccessLevel.none);
  });

  test('audit can view everything and has full access to reports, no write access anywhere', () {
    expect(checker.accessLevel(Role.audit, Resource.productsAndBatches), AccessLevel.view);
    expect(checker.accessLevel(Role.audit, Resource.storageLocations), AccessLevel.view);
    expect(checker.accessLevel(Role.audit, Resource.salesPos), AccessLevel.view);
    expect(checker.accessLevel(Role.audit, Resource.reports), AccessLevel.full);
    expect(checker.accessLevel(Role.audit, Resource.auditLog), AccessLevel.view);
    expect(checker.accessLevel(Role.audit, Resource.users), AccessLevel.none);
  });

  test('only admin may edit a stock batch that already has units sold from it', () {
    expect(checker.canEditSoldBatch(Role.admin), isTrue);
    expect(checker.canEditSoldBatch(Role.inventory), isFalse);
    expect(checker.canEditSoldBatch(Role.kasir), isFalse);
    expect(checker.canEditSoldBatch(Role.audit), isFalse);
  });
}
