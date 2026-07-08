import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/data/user_repository.dart';
import 'package:pharmacy_inventory_platform/domain/password_hasher.dart';

/// Test-only helper: seeds a single user so tests can assert the "login
/// screen" branch of the auth gate without repeating the create-user
/// boilerplate in every test file.
class UserRepositoryTestSeed {
  UserRepositoryTestSeed(this._db);

  final AppDatabase _db;

  Future<void> seedOneUser() {
    return UserRepository(_db).createUser(
      username: 'budi',
      passwordHash: PasswordHasher().hash('secret123'),
      role: 'kasir',
    );
  }
}
