import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/audit_logger.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/user_repository.dart';

void main() {
  late AppDatabase db;
  late AuditLogger logger;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    logger = AuditLogger(db);
  });

  tearDown(() => db.close());

  test('log writes a row with the given table/record/action/user', () async {
    final userRepo = UserRepository(db);
    final userId = await userRepo.createUser(
      username: 'budi',
      passwordHash: 'hashed-value',
      role: 'admin',
    );

    await logger.log(
      tableName: 'products',
      recordId: 42,
      action: 'create',
      userId: userId,
      newValue: '{"name":"Paracetamol"}',
    );

    final rows = await db.select(db.auditLogs).get();

    expect(rows, hasLength(1));
    // ponytail: column is `entityTable` in the schema (see
    // lib/data/database.dart), not `tableName` as in the plan's draft —
    // `tableName` collides with drift's `Table.tableName` getter.
    expect(rows.first.entityTable, 'products');
    expect(rows.first.recordId, 42);
    expect(rows.first.action, 'create');
    expect(rows.first.oldValue, isNull);
    expect(rows.first.newValue, '{"name":"Paracetamol"}');
  });
}
