import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/domain/permission_checker.dart';

void main() {
  late PermissionChecker checker;

  setUp(() {
    checker = PermissionChecker();
  });

  group('PermissionChecker role parsing and resource access', () {
    test('parseRole correctly normalizes string roles', () {
      expect(checker.parseRole('admin'), Role.admin);
      expect(checker.parseRole('Administrator'), Role.admin);
      expect(checker.parseRole('inventory'), Role.inventory);
      expect(checker.parseRole('Gudang'), Role.inventory);
      expect(checker.parseRole('kasir'), Role.kasir);
      expect(checker.parseRole('Cashier'), Role.kasir);
      expect(checker.parseRole('audit'), Role.audit);
      expect(checker.parseRole(null), Role.kasir);
    });

    test('canManageUsers restricts employee management to admin only', () {
      expect(checker.canManageUsers('admin'), isTrue);
      expect(checker.canManageUsers('kasir'), isFalse);
      expect(checker.canManageUsers('inventory'), isFalse);
      expect(checker.canManageUsers('audit'), isFalse);
    });

    test('canManageBackup restricts backup and restore to admin only', () {
      expect(checker.canManageBackup('admin'), isTrue);
      expect(checker.canManageBackup('kasir'), isFalse);
      expect(checker.canManageBackup('inventory'), isFalse);
      expect(checker.canManageBackup('audit'), isFalse);
    });

    test('canManageBranding restricts pharmacy branding settings to admin only', () {
      expect(checker.canManageBranding('admin'), isTrue);
      expect(checker.canManageBranding('kasir'), isFalse);
      expect(checker.canManageBranding('inventory'), isFalse);
      expect(checker.canManageBranding('audit'), isFalse);
    });

    test('canCreateProducts allows admin and inventory roles', () {
      expect(checker.canCreateProducts('admin'), isTrue);
      expect(checker.canCreateProducts('inventory'), isTrue);
      expect(checker.canCreateProducts('kasir'), isFalse);
      expect(checker.canCreateProducts('audit'), isFalse);
    });

    test('canPerformCheckout allows admin and cashier roles', () {
      expect(checker.canPerformCheckout('admin'), isTrue);
      expect(checker.canPerformCheckout('kasir'), isTrue);
      expect(checker.canPerformCheckout('inventory'), isFalse);
      expect(checker.canPerformCheckout('audit'), isFalse);
    });

    test('canManageSuppliers allows admin and inventory roles', () {
      expect(checker.canManageSuppliers('admin'), isTrue);
      expect(checker.canManageSuppliers('inventory'), isTrue);
      expect(checker.canManageSuppliers('kasir'), isFalse);
      expect(checker.canManageSuppliers('audit'), isFalse);
    });
  });
}
