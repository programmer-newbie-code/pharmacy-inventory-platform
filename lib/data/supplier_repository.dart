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
  }) async {
    final id = await _db.into(_db.suppliers).insert(
          SuppliersCompanion.insert(
            name: name,
            contactPerson: Value(contactPerson),
            phone: Value(phone),
            email: Value(email),
            address: Value(address),
            createdAt: Value(DateTime.now()),
          ),
        );

    return (_db.select(_db.suppliers)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  /// Lists all suppliers ordered by name ASC.
  Future<List<Supplier>> listSuppliers() {
    return (_db.select(_db.suppliers)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }
}
