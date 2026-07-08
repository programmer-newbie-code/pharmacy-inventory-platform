import 'package:drift/drift.dart';

import 'database.dart';

class AuditLogger {
  AuditLogger(this._db);

  final AppDatabase _db;

  Future<void> log({
    required String tableName,
    required int recordId,
    required String action,
    required int userId,
    String? oldValue,
    String? newValue,
  }) {
    return _db.into(_db.auditLogs).insert(
          // ponytail: column is `entityTable` (not `tableName`) to avoid
          // colliding with drift's own `Table.tableName` getter — see
          // lib/data/database.dart. Kept this method's param name `tableName`
          // since that's the natural call-site name for callers.
          AuditLogsCompanion.insert(
            entityTable: tableName,
            recordId: recordId,
            action: action,
            userId: userId,
            oldValue: Value(oldValue),
            newValue: Value(newValue),
          ),
        );
  }
}
