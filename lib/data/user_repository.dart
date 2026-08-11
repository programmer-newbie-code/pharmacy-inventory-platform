import 'package:drift/drift.dart';

import 'database.dart';

class UserRepository {
  UserRepository(this._db);

  final AppDatabase _db;

  Future<int> countUsers() async => (await _db.select(_db.users).get()).length;

  Future<User?> findByUsername(String username) async {
    final rows = await (_db.select(_db.users)
          ..where((tbl) => tbl.username.equals(username)))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> createUser({
    required String username,
    required String passwordHash,
    required String role,
    String? photoPath,
  }) {
    return _db.into(_db.users).insert(
          UsersCompanion.insert(
            username: username,
            passwordHash: passwordHash,
            role: role,
            photoPath: Value(photoPath),
          ),
        );
  }

  Future<List<User>> listUsers() {
    return (_db.select(_db.users)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.username)]))
        .get();
  }

  Future<bool> updateUserRole({
    required int userId,
    required String newRole,
  }) async {
    final updated = await (_db.update(_db.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .write(UsersCompanion(role: Value(newRole)));
    return updated > 0;
  }

  Future<bool> updateUserPassword({
    required int userId,
    required String newPasswordHash,
  }) async {
    final updated = await (_db.update(_db.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .write(UsersCompanion(passwordHash: Value(newPasswordHash)));
    return updated > 0;
  }

  Future<bool> updateUserPhoto({
    required int userId,
    required String? photoPath,
  }) async {
    final updated = await (_db.update(_db.users)
          ..where((tbl) => tbl.id.equals(userId)))
        .write(UsersCompanion(photoPath: Value(photoPath)));
    return updated > 0;
  }
}
