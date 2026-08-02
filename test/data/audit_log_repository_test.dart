import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/audit_log_repository.dart';

void main() {
  late AppDatabase db;
  late AuditLogRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = AuditLogRepository(db);

    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(1),
            username: 'admin',
            passwordHash: 'hash',
            role: 'admin',
          ),
        );
    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: const Value(2),
            username: 'cashier',
            passwordHash: 'hash',
            role: 'kasir',
          ),
        );

    // Seed audit logs with varied timestamps
    final base = DateTime(2026, 7, 15);
    for (int i = 0; i < 12; i++) {
      await db.into(db.auditLogs).insert(
            AuditLogsCompanion.insert(
              entityTable: i < 6 ? 'products' : 'sales',
              recordId: 100 + i,
              action: i.isEven ? 'create' : 'update',
              userId: i < 6 ? 1 : 2,
              timestamp: Value(base.add(Duration(days: i))),
            ),
          );
    }
  });

  tearDown(() async {
    await db.close();
  });

  test('returns all logs ordered newest first', () async {
    final logs = await repo.query(AuditLogFilter());
    expect(logs.length, 12);
    for (int i = 0; i < logs.length - 1; i++) {
      expect(
        logs[i].timestamp.isAfter(logs[i + 1].timestamp) ||
            logs[i].timestamp == logs[i + 1].timestamp,
        isTrue,
      );
    }
  });

  test('filters by userId', () async {
    final logs = await repo.query(AuditLogFilter(userId: 1));
    expect(logs.length, 6);
    expect(logs.every((l) => l.userId == 1), isTrue);
  });

  test('filters by entityTable', () async {
    final logs = await repo.query(AuditLogFilter(entityTable: 'sales'));
    expect(logs.length, 6);
    expect(logs.every((l) => l.entityTable == 'sales'), isTrue);
  });

  test('filters by action', () async {
    final logs = await repo.query(AuditLogFilter(action: 'create'));
    expect(logs.length, 6);
    expect(logs.every((l) => l.action == 'create'), isTrue);
  });

  test('filters by recordId', () async {
    final logs = await repo.query(AuditLogFilter(recordId: 105));
    expect(logs.length, 1);
    expect(logs.single.recordId, 105);
  });

  test('filters by inclusive date range', () async {
    final logs = await repo.query(
      AuditLogFilter(
        startDate: DateTime(2026, 7, 16),
        endDate: DateTime(2026, 7, 20),
      ),
    );
    expect(logs.length, 5); // days 16,17,18,19,20
  });

  test('paginates with limit and offset', () async {
    final page1 = await repo.query(AuditLogFilter(limit: 5, offset: 0));
    expect(page1.length, 5);

    final page2 = await repo.query(AuditLogFilter(limit: 5, offset: 5));
    expect(page2.length, 5);

    // Ensure pages don't overlap
    final ids1 = page1.map((l) => l.id).toSet();
    final ids2 = page2.map((l) => l.id).toSet();
    expect(ids1.intersection(ids2), isEmpty);
  });

  test('returns username from join', () async {
    final logs = await repo.query(AuditLogFilter(userId: 1));
    expect(logs.isNotEmpty, isTrue);
    expect(logs.first.username, 'admin');
  });
}


