import 'package:drift/drift.dart';
import 'database.dart';

class PatientRepository {
  PatientRepository(this._db);

  final AppDatabase _db;

  /// Creates a new patient.
  Future<Patient> createPatient({
    required String name,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? allergies,
    String? chronicConditions,
    String? notes,
    int? createdBy,
    String? deviceId,
  }) async {
    final id = await _db.into(_db.patients).insert(
          PatientsCompanion.insert(
            name: name,
            phone: Value(phone),
            dateOfBirth: Value(dateOfBirth),
            address: Value(address),
            allergies: Value(allergies),
            chronicConditions: Value(chronicConditions),
            notes: Value(notes),
            createdBy: Value(createdBy),
            createdAt: Value(DateTime.now()),
            deviceId: Value(deviceId),
          ),
        );

    return (_db.select(_db.patients)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  /// Updates an existing patient.
  Future<Patient> updatePatient({
    required int id,
    required String name,
    String? phone,
    DateTime? dateOfBirth,
    String? address,
    String? allergies,
    String? chronicConditions,
    String? notes,
  }) async {
    final existing = await (_db.select(_db.patients)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    final updated = existing.copyWith(
      name: name,
      phone: Value(phone),
      dateOfBirth: Value(dateOfBirth),
      address: Value(address),
      allergies: Value(allergies),
      chronicConditions: Value(chronicConditions),
      notes: Value(notes),
      updatedAt: Value(DateTime.now()),
    );

    await _db.update(_db.patients).replace(updated);
    return updated;
  }

  /// Fetches a patient by ID.
  Future<Patient?> getPatientById(int id) {
    return (_db.select(_db.patients)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Searches patients by name or phone (case-insensitive).
  Future<List<Patient>> searchPatients(String query) {
    final q = '%${query.toLowerCase()}%';
    return (_db.select(_db.patients)
          ..where((tbl) =>
              tbl.name.lower().like(q) | tbl.phone.lower().like(q))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  /// Lists all patients ordered by name ASC.
  Future<List<Patient>> listPatients() {
    return (_db.select(_db.patients)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }

  /// Returns medication history (transactions) for a patient.
  Future<List<SaleTransaction>> getPatientTransactionHistory(int patientId) {
    return (_db.select(_db.saleTransactions)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .get();
  }
}
