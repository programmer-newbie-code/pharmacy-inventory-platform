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

final excelReportServiceProvider = Provider<ExcelReportService>((ref) => ExcelReportService());

final passwordHasherProvider = Provider<PasswordHasher>((ref) => PasswordHasher());

final permissionCheckerProvider = Provider<PermissionChecker>((ref) => PermissionChecker());




