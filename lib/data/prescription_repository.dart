import 'package:drift/drift.dart';
import 'database.dart';

class PrescriptionRepository {
  PrescriptionRepository(this._db);

  final AppDatabase _db;

  /// Creates a new prescription record.
  Future<Prescription> createPrescription({
    required int patientId,
    required String doctorName,
    required DateTime prescriptionDate,
    int? transactionId,
    String? doctorSipNo,
    String? clinicName,
    String? photoPath,
    String? notes,
    bool isChronic = false,
    int? refillIntervalDays,
    DateTime? nextRefillDate,
    String? deviceId,
  }) async {
    final id = await _db.into(_db.prescriptions).insert(
          PrescriptionsCompanion.insert(
            patientId: patientId,
            doctorName: doctorName,
            prescriptionDate: prescriptionDate,
            transactionId: Value(transactionId),
            doctorSipNo: Value(doctorSipNo),
            clinicName: Value(clinicName),
            photoPath: Value(photoPath),
            notes: Value(notes),
            isChronic: Value(isChronic),
            refillIntervalDays: Value(refillIntervalDays),
            nextRefillDate: Value(nextRefillDate),
            createdAt: Value(DateTime.now()),
            deviceId: Value(deviceId),
          ),
        );

    return (_db.select(_db.prescriptions)..where((tbl) => tbl.id.equals(id)))
        .getSingle();
  }

  /// Lists all prescriptions for a patient.
  Future<List<Prescription>> getPrescriptionsForPatient(int patientId) {
    return (_db.select(_db.prescriptions)
          ..where((tbl) => tbl.patientId.equals(patientId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.prescriptionDate)]))
        .get();
  }

  /// Returns chronic prescriptions with upcoming refill dates within [withinDays].
  Future<List<Prescription>> getUpcomingRefills({int withinDays = 7}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: withinDays));

    return (_db.select(_db.prescriptions)
          ..where((tbl) =>
              tbl.isChronic.equals(true) &
              tbl.nextRefillDate.isNotNull() &
              tbl.nextRefillDate.isSmallerOrEqualValue(cutoff))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.nextRefillDate)]))
        .get();
  }
}
