import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audit_logger.dart';
import '../data/database.dart';
import '../data/user_repository.dart';
import '../domain/password_hasher.dart';
import '../domain/permission_checker.dart';

import '../data/product_repository.dart';
import '../data/stock_batch_repository.dart';

import '../data/sale_repository.dart';

import '../data/alert_repository.dart';

import '../data/report_repository.dart';
import '../data/backup_service.dart';
import '../data/excel_report_service.dart';
import '../data/google_drive_backup_service.dart';
import '../data/csv_import_service.dart';
import '../data/receipt_pdf_service.dart';
import '../data/cashier_shift_repository.dart';
import '../data/return_repository.dart';
import '../data/supplier_repository.dart';
import '../data/purchase_order_repository.dart';
import '../data/purchase_receiving_repository.dart';
import '../data/patient_repository.dart';
import '../data/prescription_repository.dart';
import '../data/pharmacy_settings_service.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../data/app_update_service.dart';
import '../data/audit_log_repository.dart';
import '../data/auto_backup_scheduler.dart';
import '../data/drive_credential_store.dart';
import '../data/drug_catalog_updater.dart';
import '../data/drug_lookup_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaultConnection();
  ref.onDispose(db.close);
  return db;
});

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(ref.watch(databaseProvider)),
);

final auditLoggerProvider = Provider<AuditLogger>(
  (ref) => AuditLogger(ref.watch(databaseProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(
    ref.watch(databaseProvider),
    auditLogger: ref.watch(auditLoggerProvider),
  ),
);

final stockBatchRepositoryProvider = Provider<StockBatchRepository>(
  (ref) => StockBatchRepository(
    ref.watch(databaseProvider),
    auditLogger: ref.watch(auditLoggerProvider),
  ),
);

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepository(
    ref.watch(databaseProvider),
    auditLogger: ref.watch(auditLoggerProvider),
  ),
);

final alertRepositoryProvider = Provider<AlertRepository>(
  (ref) => AlertRepository(ref.watch(databaseProvider)),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(databaseProvider)),
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(databaseProvider)),
);

final driveCredentialStoreProvider = Provider<DriveCredentialStore>(
  (ref) => DriveCredentialStore(),
);

final googleDriveBackupServiceProvider = Provider<GoogleDriveBackupService>(
  (ref) => GoogleDriveBackupService(
    ref.watch(databaseProvider),
    credentialStore: ref.watch(driveCredentialStoreProvider),
  ),
);

final excelReportServiceProvider = Provider<ExcelReportService>((ref) => ExcelReportService());

final csvImportServiceProvider = Provider<CsvImportService>(
  (ref) => CsvImportService(ref.watch(productRepositoryProvider)),
);

final receiptPdfServiceProvider = Provider<ReceiptPdfService>((ref) => ReceiptPdfService());

final cashierShiftRepositoryProvider = Provider<CashierShiftRepository>(
  (ref) => CashierShiftRepository(ref.watch(databaseProvider)),
);

final returnRepositoryProvider = Provider<ReturnRepository>(
  (ref) => ReturnRepository(
    ref.watch(databaseProvider),
    auditLogger: ref.watch(auditLoggerProvider),
  ),
);

final supplierRepositoryProvider = Provider<SupplierRepository>(
  (ref) => SupplierRepository(ref.watch(databaseProvider)),
);

final purchaseOrderRepositoryProvider = Provider<PurchaseOrderRepository>(
  (ref) => PurchaseOrderRepository(
    ref.watch(databaseProvider),
    auditLogger: ref.watch(auditLoggerProvider),
  ),
);

final purchaseReceivingRepositoryProvider = Provider<PurchaseReceivingRepository>(
  (ref) => PurchaseReceivingRepository(
    ref.watch(databaseProvider),
    auditLogger: ref.watch(auditLoggerProvider),
  ),
);

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => PatientRepository(ref.watch(databaseProvider)),
);

final prescriptionRepositoryProvider = Provider<PrescriptionRepository>(
  (ref) => PrescriptionRepository(ref.watch(databaseProvider)),
);

final pharmacySettingsServiceProvider = Provider<PharmacySettingsService>(
  (ref) => PharmacySettingsService(),
);

final drugCatalogUpdaterProvider = Provider<DrugCatalogUpdater>(
  (ref) => DrugCatalogUpdater(),
);

final drugLookupServiceProvider = Provider<DrugLookupService>(
  (ref) => DrugLookupService(
    catalogUpdater: ref.watch(drugCatalogUpdaterProvider),
  ),
);

final passwordHasherProvider = Provider<PasswordHasher>((ref) => PasswordHasher());



final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (ref) => AuditLogRepository(ref.watch(databaseProvider)),
);

final permissionCheckerProvider = Provider<PermissionChecker>((ref) => PermissionChecker());

final autoBackupSchedulerProvider = Provider<AutoBackupScheduler>((ref) {
  final scheduler = AutoBackupScheduler(
    backupService: ref.watch(backupServiceProvider),
    driveBackupService: ref.watch(googleDriveBackupServiceProvider),
  );
  ref.onDispose(scheduler.stop);
  return scheduler;
});
final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => AppUpdateService(),
);

final appUpdateCheckFutureProvider = FutureProvider.autoDispose<AppUpdateInfo?>((ref) async {
  final service = ref.watch(appUpdateServiceProvider);
  final info = await PackageInfo.fromPlatform();
  if (info.version.isEmpty) return null;
  return service.checkForUpdates(currentVersion: info.version);
});
