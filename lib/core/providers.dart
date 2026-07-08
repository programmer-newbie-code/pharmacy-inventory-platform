import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audit_logger.dart';
import '../data/database.dart';
import '../data/user_repository.dart';
import '../domain/password_hasher.dart';
import '../domain/permission_checker.dart';

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

final passwordHasherProvider = Provider<PasswordHasher>((ref) => PasswordHasher());

final permissionCheckerProvider = Provider<PermissionChecker>((ref) => PermissionChecker());
