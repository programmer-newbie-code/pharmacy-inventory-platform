import 'package:drift/drift.dart';
import 'database.dart';

/// A query result row for the audit explorer.
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    required this.entityTable,
    required this.recordId,
    required this.action,
    required this.userId,
    required this.username,
    required this.timestamp,
    this.oldValue,
    this.newValue,
  });

  final int id;
  final String entityTable;
  final int recordId;
  final String action;
  final int userId;
  final String username;
  final DateTime timestamp;
  final String? oldValue;
  final String? newValue;
}

/// Filters for querying audit logs.
class AuditLogFilter {
  const AuditLogFilter({
    this.userId,
    this.entityTable,
    this.action,
    this.recordId,
    this.startDate,
    this.endDate,
    this.limit,
    this.offset,
  });

  final int? userId;
  final String? entityTable;
  final String? action;
  final int? recordId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? limit;
  final int? offset;
}

class AuditLogRepository {
  AuditLogRepository(this._db);

  final AppDatabase _db;

  /// Queries audit logs with optional filters, pagination, and ordering (newest first).
  Future<List<AuditLogEntry>> query(AuditLogFilter filter) async {
    final query = _db.select(_db.auditLogs).join([
      innerJoin(_db.users, _db.users.id.equalsExp(_db.auditLogs.userId)),
    ]);

    if (filter.userId != null) {
      query.where(_db.auditLogs.userId.equals(filter.userId!));
    }
    if (filter.entityTable != null) {
      query.where(_db.auditLogs.entityTable.equals(filter.entityTable!));
    }
    if (filter.action != null) {
      query.where(_db.auditLogs.action.equals(filter.action!));
    }
    if (filter.recordId != null) {
      query.where(_db.auditLogs.recordId.equals(filter.recordId!));
    }
    if (filter.startDate != null) {
      query.where(
        _db.auditLogs.timestamp.isBiggerOrEqual(Variable(filter.startDate!)),
      );
    }
    if (filter.endDate != null) {
      query.where(
        _db.auditLogs.timestamp.isSmallerOrEqual(Variable(filter.endDate!)),
      );
    }

    query.orderBy([OrderingTerm.desc(_db.auditLogs.timestamp)]);

    if (filter.limit != null) {
      query.limit(filter.limit!, offset: filter.offset ?? 0);
    }

    final rows = await query.get();
    return rows.map((row) {
      final log = row.readTable(_db.auditLogs);
      final user = row.readTable(_db.users);
      return AuditLogEntry(
        id: log.id,
        entityTable: log.entityTable,
        recordId: log.recordId,
        action: log.action,
        userId: log.userId,
        username: user.username,
        timestamp: log.timestamp,
        oldValue: log.oldValue,
        newValue: log.newValue,
      );
    }).toList();
  }
}

