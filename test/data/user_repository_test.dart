import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/user_repository.dart';

void main() {
  late AppDatabase db;
  late UserRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserRepository(db);
  });

  tearDown(() => db.close());

  test('countUsers is 0 on a fresh database', () async {
    expect(await repo.countUsers(), 0);
  });

  test('createUser then findByUsername returns the same user', () async {
    await repo.createUser(
      username: 'budi',
      passwordHash: 'hashed-value',
      role: 'admin',
    );

    final found = await repo.findByUsername('budi');

    expect(found, isNotNull);
    expect(found!.role, 'admin');
    expect(await repo.countUsers(), 1);
  });

  test('findByUsername returns null for a username that does not exist', () async {
    expect(await repo.findByUsername('nobody'), isNull);
  });
}
