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

  test('findByUsername returns null for a username that does not exist',
      () async {
    expect(await repo.findByUsername('nobody'), isNull);
  });

  test('listUsers returns all users ordered by username', () async {
    await repo.createUser(
        username: 'siti', passwordHash: 'hash', role: 'kasir');
    await repo.createUser(
        username: 'andi', passwordHash: 'hash', role: 'inventory');

    final users = await repo.listUsers();
    expect(users, hasLength(2));
    expect(users.first.username, equals('andi'));
    expect(users.last.username, equals('siti'));
  });

  test('updateUserRole and updateUserPassword modify user details', () async {
    final id = await repo.createUser(
        username: 'budi', passwordHash: 'old-hash', role: 'kasir');

    final roleUpdated = await repo.updateUserRole(userId: id, newRole: 'admin');
    expect(roleUpdated, isTrue);

    final passUpdated =
        await repo.updateUserPassword(userId: id, newPasswordHash: 'new-hash');
    expect(passUpdated, isTrue);

    final user = await repo.findByUsername('budi');
    expect(user!.role, equals('admin'));
    expect(user.passwordHash, equals('new-hash'));
  });

  test('stores and clears a user photo path', () async {
    final id = await repo.createUser(
      username: 'photo-user',
      passwordHash: 'hash',
      role: 'kasir',
      photoPath: '/images/original.jpg',
    );
    expect((await repo.findByUsername('photo-user'))!.photoPath,
        '/images/original.jpg');

    expect(await repo.updateUserPhoto(userId: id, photoPath: '/images/new.jpg'),
        isTrue);
    expect((await repo.findByUsername('photo-user'))!.photoPath,
        '/images/new.jpg');

    expect(await repo.updateUserPhoto(userId: id, photoPath: null), isTrue);
    expect((await repo.findByUsername('photo-user'))!.photoPath, isNull);
  });
}
