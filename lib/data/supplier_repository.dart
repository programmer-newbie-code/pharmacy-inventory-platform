import 'package:drift/drift.dart';
import 'database.dart';

class SupplierRepository {
  SupplierRepository(this._db);

  final AppDatabase _db;

  /// Creates a new supplier record.
  Future<Supplier> createSupplier({
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? paymentTerms,
    int leadTimeDays = 7,
  }) async {
    final id = await _db.into(_db.suppliers).insert(
          SuppliersCompanion.insert(
            name: name,
            contactPerson: Value(contactPerson),
            phone: Value(phone),
            email: Value(email),
            address: Value(address),
            paymentTerms: Value(paymentTerms),
            leadTimeDays: Value(leadTimeDays),
            isActive: const Value(true),
            createdAt: Value(DateTime.now()),
          ),
        );

    return (_db.select(_db.suppliers)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  /// Updates an existing supplier.
  Future<Supplier> updateSupplier({
    required int id,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? paymentTerms,
    int? leadTimeDays,
  }) async {
    final existing = await (_db.select(_db.suppliers)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    final updated = existing.copyWith(
      name: name,
      contactPerson: Value(contactPerson),
      phone: Value(phone),
      email: Value(email),
      address: Value(address),
      paymentTerms: Value(paymentTerms),
      leadTimeDays: leadTimeDays ?? existing.leadTimeDays,
      updatedAt: Value(DateTime.now()),
    );

    await _db.update(_db.suppliers).replace(updated);
    return updated;
  }

  /// Soft-deactivates a supplier (preserves history).
  Future<void> deactivateSupplier(int id) async {
    final existing = await (_db.select(_db.suppliers)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    await _db.update(_db.suppliers).replace(
          existing.copyWith(
            isActive: false,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Reactivates a previously deactivated supplier.
  Future<void> activateSupplier(int id) async {
    final existing = await (_db.select(_db.suppliers)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    await _db.update(_db.suppliers).replace(
          existing.copyWith(
            isActive: true,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Lists all suppliers ordered by name ASC.
  Future<List<Supplier>> listSuppliers() {
    return (_db.select(_db.suppliers)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  /// Lists only active suppliers.
  Future<List<Supplier>> listActiveSuppliers() {
    return (_db.select(_db.suppliers)
          ..where((tbl) => tbl.isActive.equals(true))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  /// Searches suppliers by name (case-insensitive partial match).
  Future<List<Supplier>> searchSuppliers(String query) {
    return (_db.select(_db.suppliers)
          ..where((tbl) => tbl.name.lower().like('%${query.toLowerCase()}%'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  /// Fetches a single supplier by ID.
  Future<Supplier> getSupplier(int id) {
    return (_db.select(_db.suppliers)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }
}
