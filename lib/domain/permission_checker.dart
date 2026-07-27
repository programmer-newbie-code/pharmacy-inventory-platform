enum Role { admin, inventory, kasir, audit }

enum Resource { productsAndBatches, storageLocations, salesPos, reports, auditLog, users }

/// `viewOwn` is narrower than `view` — used only for kasir/reports, where a
/// cashier sees their own transactions, not the whole store's.
enum AccessLevel { none, viewOwn, view, create, full }

/// Encodes the role/resource matrix from the design spec, §5.
class PermissionChecker {
  static const Map<Role, Map<Resource, AccessLevel>> _matrix = {
    Role.admin: {
      Resource.productsAndBatches: AccessLevel.full,
      Resource.storageLocations: AccessLevel.full,
      Resource.salesPos: AccessLevel.full,
      Resource.reports: AccessLevel.full,
      Resource.auditLog: AccessLevel.view,
      Resource.users: AccessLevel.full,
    },
    Role.inventory: {
      Resource.productsAndBatches: AccessLevel.full,
      Resource.storageLocations: AccessLevel.full,
      Resource.salesPos: AccessLevel.view,
      Resource.reports: AccessLevel.view,
      Resource.auditLog: AccessLevel.none,
      Resource.users: AccessLevel.none,
    },
    Role.kasir: {
      Resource.productsAndBatches: AccessLevel.view,
      Resource.storageLocations: AccessLevel.view,
      Resource.salesPos: AccessLevel.create,
      Resource.reports: AccessLevel.viewOwn,
      Resource.auditLog: AccessLevel.none,
      Resource.users: AccessLevel.none,
    },
    Role.audit: {
      Resource.productsAndBatches: AccessLevel.view,
      Resource.storageLocations: AccessLevel.view,
      Resource.salesPos: AccessLevel.view,
      Resource.reports: AccessLevel.full,
      Resource.auditLog: AccessLevel.view,
      Resource.users: AccessLevel.none,
    },
  };

  AccessLevel accessLevel(Role role, Resource resource) => _matrix[role]![resource]!;

  /// Inventory's "full*" access to products/batches in the spec has one carve-out:
  /// once any unit has been sold from a batch, only admin may edit its cost/expiry.
  bool canEditSoldBatch(Role role) => role == Role.admin;
}
