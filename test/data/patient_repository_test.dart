import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/patient_repository.dart';
import 'package:pharmacy_inventory_platform/data/prescription_repository.dart';

void main() {
  late AppDatabase db;
  late PatientRepository patientRepo;
  late PrescriptionRepository rxRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    patientRepo = PatientRepository(db);
    rxRepo = PrescriptionRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('patient CRUD and search operations work correctly', () async {
    final p1 = await patientRepo.createPatient(
      name: 'Budi Santoso',
      phone: '081234567890',
      address: 'Jl. Merdeka No. 10',
      allergies: 'Penicillin',
      chronicConditions: 'Diabetes',
    );

    expect(p1.name, equals('Budi Santoso'));
    expect(p1.phone, equals('081234567890'));
    expect(p1.allergies, equals('Penicillin'));

    // Search by name
    final searchName = await patientRepo.searchPatients('Budi');
    expect(searchName, hasLength(1));

    // Search by phone
    final searchPhone = await patientRepo.searchPatients('0812');
    expect(searchPhone, hasLength(1));

    // Update patient
    final updated = await patientRepo.updatePatient(
      id: p1.id,
      name: 'Budi Santoso S.H.',
      phone: '081234567890',
      allergies: 'Penicillin, Sulfa',
    );
    expect(updated.name, equals('Budi Santoso S.H.'));
    expect(updated.allergies, equals('Penicillin, Sulfa'));

    final fetched = await patientRepo.getPatientById(p1.id);
    expect(fetched?.name, equals('Budi Santoso S.H.'));
  });

  test('prescription creation and upcoming chronic refills query', () async {
    final patient = await patientRepo.createPatient(name: 'Siti Rahma');

    final rx1 = await rxRepo.createPrescription(
      patientId: patient.id,
      doctorName: 'Ahmad',
      doctorSipNo: 'SIP/123/2026',
      clinicName: 'Klinik Sehat',
      prescriptionDate: DateTime.now(),
      isChronic: true,
      refillIntervalDays: 30,
      nextRefillDate: DateTime.now().add(const Duration(days: 3)),
    );

    expect(rx1.doctorName, equals('Ahmad'));
    expect(rx1.isChronic, isTrue);

    final patientRxs = await rxRepo.getPrescriptionsForPatient(patient.id);
    expect(patientRxs, hasLength(1));

    final upcomingRefills = await rxRepo.getUpcomingRefills(withinDays: 7);
    expect(upcomingRefills, hasLength(1));
    expect(upcomingRefills.first.patientId, equals(patient.id));
  });
}
