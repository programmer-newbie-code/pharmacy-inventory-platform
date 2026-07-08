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
  }) {
    return _db.into(_db.users).insert(
          UsersCompanion.insert(
            username: username,
            passwordHash: passwordHash,
            role: role,
          ),
        );
  }
}
