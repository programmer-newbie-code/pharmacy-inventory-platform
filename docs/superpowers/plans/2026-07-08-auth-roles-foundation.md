# Authentication & Roles Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a pharmacy staff member log in, enforce the role matrix from the design
spec (§5), and give every future feature a reusable audit-log write path — this is
the foundation POS/inventory screens build on next (they all need "who is the current
user" and "is this action allowed").

**Architecture:** `lib/domain/password_hasher.dart` and
`lib/domain/permission_checker.dart` (pure Dart, no Flutter/drift — the same rule as
the rest of `domain/`). `lib/data/user_repository.dart` and
`lib/data/audit_logger.dart` (drift-backed). `lib/core/providers.dart` for DI (the
`core/` slot the design spec reserved for this). `lib/features/auth/` for the
session notifier and two screens (first-run setup, login).

**Tech Stack:** adds `bcrypt` (pure-Dart password hashing — chosen over
`flutter_bcrypt` specifically because that one needs native iOS/Android platform
channels and won't run on Windows desktop; this app targets Windows + Android from
one codebase, so it must be pure Dart). Everything else is already in `pubspec.yaml`.

**Assumptions made autonomously (flag if wrong, easy to change):**
- No "remember me" / persisted session — the app asks for login every launch. Simplest
  thing that works; add persistence later if it's actually annoying in practice.
- First-run experience: if the `users` table is empty, show a "create the first admin
  account" screen instead of login — there's no other way to provision a user on a
  purely local, offline app with no server. This isn't in the design spec (which
  assumes users already exist) — necessary to make the app usable from a cold start.
- User management beyond creating the first admin (editing/deactivating other users)
  is **not** built here — YAGNI until there's a concrete need; the `admin` role's
  "full" access to Users in the spec's matrix is partially implemented (create-only).
  Flagged as follow-up, not silently dropped.

**Out of scope for this plan:** POS/inventory screens that will *use*
`permission_checker.dart`/`audit_logger.dart` (separate future plans), user
edit/deactivate screens (see assumption above), password reset (no email/SMS channel
exists on a local app — out of scope until there's a concrete recovery mechanism to
design).

---

### Task 1: Password hashing (TDD)

**Files:**
- Modify: `pubspec.yaml` (add `bcrypt: ^1.1.3` under `dependencies`)
- Create: `lib/domain/password_hasher.dart`
- Test: `test/domain/password_hasher_test.dart`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:` (alongside the existing `path: ^1.9.0` line),
add:

```yaml
  bcrypt: ^1.1.3
```

Run: `flutter pub get`
Expected: `+ bcrypt 1.1.3` (or newer) in the output, `Got dependencies.`

- [ ] **Step 2: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/domain/password_hasher.dart';

void main() {
  final hasher = PasswordHasher();

  test('verify returns true for the password that was hashed', () {
    final hash = hasher.hash('correct horse battery staple');
    expect(hasher.verify('correct horse battery staple', hash), isTrue);
  });

  test('verify returns false for a wrong password', () {
    final hash = hasher.hash('correct horse battery staple');
    expect(hasher.verify('wrong password', hash), isFalse);
  });

  test('hashing the same password twice produces different hashes (random salt)', () {
    final first = hasher.hash('same password');
    final second = hasher.hash('same password');
    expect(first, isNot(equals(second)));
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/domain/password_hasher_test.dart`
Expected: FAIL — `PasswordHasher` is undefined.

- [ ] **Step 4: Write minimal implementation**

```dart
import 'package:bcrypt/bcrypt.dart';

/// Wraps bcrypt so the rest of the app never imports a crypto library
/// directly — if the hashing scheme ever changes, this is the one file that
/// changes.
class PasswordHasher {
  String hash(String plainPassword) => BCrypt.hashpw(plainPassword, BCrypt.gensalt());

  bool verify(String plainPassword, String hashedPassword) =>
      BCrypt.checkpw(plainPassword, hashedPassword);
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/domain/password_hasher_test.dart`
Expected: `00:0X +3: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/domain/password_hasher.dart test/domain/password_hasher_test.dart
git commit -m "feat(auth): add bcrypt password hashing"
```

---

### Task 2: Permission matrix (TDD)

**Files:**
- Create: `lib/domain/permission_checker.dart`
- Test: `test/domain/permission_checker_test.dart`

This encodes the exact table from the design spec §5. Read it again before touching
this file if the table ever changes — this is the single place that table becomes
code.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/domain/permission_checker.dart';

void main() {
  final checker = PermissionChecker();

  test('admin has full access to every resource except audit log (view-only)', () {
    for (final resource in Resource.values.where((r) => r != Resource.auditLog)) {
      expect(checker.accessLevel(Role.admin, resource), AccessLevel.full,
          reason: 'admin should have full access to $resource');
    }
    expect(checker.accessLevel(Role.admin, Resource.auditLog), AccessLevel.view);
  });

  test('inventory can manage products/batches and storage locations, view-only elsewhere', () {
    expect(checker.accessLevel(Role.inventory, Resource.productsAndBatches), AccessLevel.full);
    expect(checker.accessLevel(Role.inventory, Resource.storageLocations), AccessLevel.full);
    expect(checker.accessLevel(Role.inventory, Resource.salesPos), AccessLevel.view);
    expect(checker.accessLevel(Role.inventory, Resource.reports), AccessLevel.view);
    expect(checker.accessLevel(Role.inventory, Resource.auditLog), AccessLevel.none);
    expect(checker.accessLevel(Role.inventory, Resource.users), AccessLevel.none);
  });

  test('kasir can only view catalog data, create sales, and view own reports', () {
    expect(checker.accessLevel(Role.kasir, Resource.productsAndBatches), AccessLevel.view);
    expect(checker.accessLevel(Role.kasir, Resource.storageLocations), AccessLevel.view);
    expect(checker.accessLevel(Role.kasir, Resource.salesPos), AccessLevel.create);
    expect(checker.accessLevel(Role.kasir, Resource.reports), AccessLevel.viewOwn);
    expect(checker.accessLevel(Role.kasir, Resource.auditLog), AccessLevel.none);
    expect(checker.accessLevel(Role.kasir, Resource.users), AccessLevel.none);
  });

  test('audit can view everything and has full access to reports, no write access anywhere', () {
    expect(checker.accessLevel(Role.audit, Resource.productsAndBatches), AccessLevel.view);
    expect(checker.accessLevel(Role.audit, Resource.storageLocations), AccessLevel.view);
    expect(checker.accessLevel(Role.audit, Resource.salesPos), AccessLevel.view);
    expect(checker.accessLevel(Role.audit, Resource.reports), AccessLevel.full);
    expect(checker.accessLevel(Role.audit, Resource.auditLog), AccessLevel.view);
    expect(checker.accessLevel(Role.audit, Resource.users), AccessLevel.none);
  });

  test('only admin may edit a stock batch that already has units sold from it', () {
    expect(checker.canEditSoldBatch(Role.admin), isTrue);
    expect(checker.canEditSoldBatch(Role.inventory), isFalse);
    expect(checker.canEditSoldBatch(Role.kasir), isFalse);
    expect(checker.canEditSoldBatch(Role.audit), isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/permission_checker_test.dart`
Expected: FAIL — `PermissionChecker`/`Role`/`Resource`/`AccessLevel` undefined.

- [ ] **Step 3: Write minimal implementation**

```dart
enum Role { admin, inventory, kasir, audit }

enum Resource { productsAndBatches, storageLocations, salesPos, reports, auditLog, users }

/// `viewOwn` is narrower than `view` — used only for kasir/reports, where a
/// cashier sees their own transactions, not the whole store's.
enum AccessLevel { none, viewOwn, view, create, full }

/// Encodes the role/resource matrix from the design spec, §5.
class PermissionChecker {
  static const Map<Role, Map<Resource, AccessLevel>> _matrix = {
    Role.admin: {
      Resource.productsAndBatches: AccessLevel.full,
      Resource.storageLocations: AccessLevel.full,
      Resource.salesPos: AccessLevel.full,
      Resource.reports: AccessLevel.full,
      Resource.auditLog: AccessLevel.view,
      Resource.users: AccessLevel.full,
    },
    Role.inventory: {
      Resource.productsAndBatches: AccessLevel.full,
      Resource.storageLocations: AccessLevel.full,
      Resource.salesPos: AccessLevel.view,
      Resource.reports: AccessLevel.view,
      Resource.auditLog: AccessLevel.none,
      Resource.users: AccessLevel.none,
    },
    Role.kasir: {
      Resource.productsAndBatches: AccessLevel.view,
      Resource.storageLocations: AccessLevel.view,
      Resource.salesPos: AccessLevel.create,
      Resource.reports: AccessLevel.viewOwn,
      Resource.auditLog: AccessLevel.none,
      Resource.users: AccessLevel.none,
    },
    Role.audit: {
      Resource.productsAndBatches: AccessLevel.view,
      Resource.storageLocations: AccessLevel.view,
      Resource.salesPos: AccessLevel.view,
      Resource.reports: AccessLevel.full,
      Resource.auditLog: AccessLevel.view,
      Resource.users: AccessLevel.none,
    },
  };

  AccessLevel accessLevel(Role role, Resource resource) => _matrix[role]![resource]!;

  /// Inventory's "full*" access to products/batches in the spec has one carve-out:
  /// once any unit has been sold from a batch, only admin may edit its cost/expiry.
  bool canEditSoldBatch(Role role) => role == Role.admin;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/domain/permission_checker_test.dart`
Expected: `00:0X +5: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/domain/permission_checker.dart test/domain/permission_checker_test.dart
git commit -m "feat(auth): add role permission matrix from design spec"
```

---

### Task 3: User repository + audit logger + DI providers

**Files:**
- Create: `lib/data/user_repository.dart`
- Create: `lib/data/audit_logger.dart`
- Create: `lib/core/providers.dart`
- Test: `test/data/user_repository_test.dart`
- Test: `test/data/audit_logger_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/data/user_repository_test.dart
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
```

```dart
// test/data/audit_logger_test.dart
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
    expect(rows.first.tableName, 'products');
    expect(rows.first.recordId, 42);
    expect(rows.first.action, 'create');
    expect(rows.first.oldValue, isNull);
    expect(rows.first.newValue, '{"name":"Paracetamol"}');
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/data/user_repository_test.dart test/data/audit_logger_test.dart`
Expected: FAIL — `UserRepository`/`AuditLogger` undefined.

- [ ] **Step 3: Write `lib/data/user_repository.dart`**

```dart
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
```

- [ ] **Step 4: Write `lib/data/audit_logger.dart`**

```dart
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
          AuditLogsCompanion.insert(
            tableName: tableName,
            recordId: recordId,
            action: action,
            userId: userId,
            oldValue: Value(oldValue),
            newValue: Value(newValue),
          ),
        );
  }
}
```

- [ ] **Step 5: Write `lib/core/providers.dart`**

```dart
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
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/data/user_repository_test.dart test/data/audit_logger_test.dart`
Expected: `00:0X +4: All tests passed!`

- [ ] **Step 7: Commit**

```bash
git add lib/data/user_repository.dart lib/data/audit_logger.dart lib/core/providers.dart test/data/user_repository_test.dart test/data/audit_logger_test.dart
git commit -m "feat(auth): add user repository, audit logger, and DI providers"
```

---

### Task 4: Auth session (Riverpod)

**Files:**
- Create: `lib/features/auth/auth_session.dart`
- Test: `test/features/auth/auth_session_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';

void main() {
  test('login succeeds with the right password and fails with the wrong one', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);
    addTearDown(db.close);

    final hasher = container.read(passwordHasherProvider);
    await container.read(userRepositoryProvider).createUser(
          username: 'budi',
          passwordHash: hasher.hash('secret123'),
          role: 'admin',
        );

    expect(container.read(authSessionProvider), isNull);

    final wrongPassword = await container
        .read(authSessionProvider.notifier)
        .login('budi', 'wrong-password');
    expect(wrongPassword, isFalse);
    expect(container.read(authSessionProvider), isNull);

    final rightPassword = await container
        .read(authSessionProvider.notifier)
        .login('budi', 'secret123');
    expect(rightPassword, isTrue);
    expect(container.read(authSessionProvider)!.username, 'budi');

    container.read(authSessionProvider.notifier).logout();
    expect(container.read(authSessionProvider), isNull);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/auth/auth_session_test.dart`
Expected: FAIL — `authSessionProvider`/`AuthSession` undefined.

- [ ] **Step 3: Write `lib/features/auth/auth_session.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/database.dart';

class AuthSession extends Notifier<User?> {
  @override
  User? build() => null;

  /// Returns true and updates state on success; returns false and leaves
  /// state unchanged on a bad username or password.
  Future<bool> login(String username, String password) async {
    final user = await ref.read(userRepositoryProvider).findByUsername(username);
    if (user == null) return false;

    final passwordMatches =
        ref.read(passwordHasherProvider).verify(password, user.passwordHash);
    if (!passwordMatches) return false;

    state = user;
    return true;
  }

  void logout() => state = null;
}

final authSessionProvider = NotifierProvider<AuthSession, User?>(AuthSession.new);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/auth/auth_session_test.dart`
Expected: `00:0X +1: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/auth_session.dart test/features/auth/auth_session_test.dart
git commit -m "feat(auth): add login session notifier"
```

---

### Task 5: First-run admin setup screen

**Files:**
- Create: `lib/features/auth/setup_admin_screen.dart`
- Test: `test/features/auth/setup_admin_screen_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`

- [ ] **Step 1: Add localized strings**

In `lib/l10n/app_en.arb`, add (keeping the existing `appTitle` key):

```json
{
  "@@locale": "en",
  "appTitle": "Pharmacy Inventory Platform",
  "setupAdminTitle": "Create the first admin account",
  "usernameLabel": "Username",
  "passwordLabel": "Password",
  "createAccountButton": "Create account",
  "setupAdminError": "Could not create the account. Try a different username."
}
```

In `lib/l10n/app_id.arb`, add:

```json
{
  "@@locale": "id",
  "appTitle": "Platform Inventaris Apotek",
  "setupAdminTitle": "Buat akun admin pertama",
  "usernameLabel": "Nama pengguna",
  "passwordLabel": "Kata sandi",
  "createAccountButton": "Buat akun",
  "setupAdminError": "Akun tidak bisa dibuat. Coba nama pengguna lain."
}
```

- [ ] **Step 2: Write the failing widget test**

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/auth/setup_admin_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('creating the first admin logs them in', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: SetupAdminScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('setupAdminUsername')), 'budi');
    await tester.enterText(find.byKey(const Key('setupAdminPassword')), 'secret123');
    await tester.tap(find.byKey(const Key('setupAdminSubmit')));
    await tester.pumpAndSettle();

    expect(container.read(authSessionProvider)?.username, 'budi');
    expect(container.read(authSessionProvider)?.role, 'admin');
    expect(await container.read(userRepositoryProvider).countUsers(), 1);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/auth/setup_admin_screen_test.dart`
Expected: FAIL — `SetupAdminScreen` undefined.

- [ ] **Step 4: Write `lib/features/auth/setup_admin_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../l10n/app_localizations.dart';
import 'auth_session.dart';

class SetupAdminScreen extends ConsumerStatefulWidget {
  const SetupAdminScreen({super.key});

  @override
  ConsumerState<SetupAdminScreen> createState() => _SetupAdminScreenState();
}

class _SetupAdminScreenState extends ConsumerState<SetupAdminScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorText = l10n.setupAdminError);
      return;
    }

    try {
      final hash = ref.read(passwordHasherProvider).hash(password);
      await ref.read(userRepositoryProvider).createUser(
            username: username,
            passwordHash: hash,
            role: 'admin',
          );
      await ref.read(authSessionProvider.notifier).login(username, password);
    } catch (_) {
      setState(() => _errorText = l10n.setupAdminError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.setupAdminTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: const Key('setupAdminUsername'),
              controller: _usernameController,
              decoration: InputDecoration(labelText: l10n.usernameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('setupAdminPassword'),
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.passwordLabel),
            ),
            const SizedBox(height: 24),
            if (_errorText != null) ...[
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('setupAdminSubmit'),
                onPressed: _submit,
                child: Text(l10n.createAccountButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/auth/setup_admin_screen_test.dart`
Expected: `00:0X +1: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_id.arb lib/features/auth/setup_admin_screen.dart test/features/auth/setup_admin_screen_test.dart
git commit -m "feat(auth): add first-run admin account setup screen"
```

---

### Task 6: Login screen

**Files:**
- Create: `lib/features/auth/login_screen.dart`
- Test: `test/features/auth/login_screen_test.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`

- [ ] **Step 1: Add localized strings**

Add to `lib/l10n/app_en.arb` (alongside the existing keys from Task 5):

```json
  "loginTitle": "Log in",
  "loginButton": "Log in",
  "loginError": "Wrong username or password. Try again."
```

Add to `lib/l10n/app_id.arb`:

```json
  "loginTitle": "Masuk",
  "loginButton": "Masuk",
  "loginError": "Nama pengguna atau kata sandi salah. Coba lagi."
```

(Remember: valid JSON — add a comma after the preceding key in each file.)

- [ ] **Step 2: Write the failing widget test**

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/auth/login_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  Future<ProviderContainer> setUpWithOneUser(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    final hash = container.read(passwordHasherProvider).hash('secret123');
    await container.read(userRepositoryProvider).createUser(
          username: 'budi',
          passwordHash: hash,
          role: 'kasir',
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: LoginScreen(),
        ),
      ),
    );
    return container;
  }

  testWidgets('correct credentials log the user in', (tester) async {
    final container = await setUpWithOneUser(tester);

    await tester.enterText(find.byKey(const Key('loginUsername')), 'budi');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'secret123');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();

    expect(container.read(authSessionProvider)?.username, 'budi');
  });

  testWidgets('wrong password shows the error and does not log in', (tester) async {
    final container = await setUpWithOneUser(tester);

    await tester.enterText(find.byKey(const Key('loginUsername')), 'budi');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'wrong');
    await tester.tap(find.byKey(const Key('loginSubmit')));
    await tester.pumpAndSettle();

    expect(container.read(authSessionProvider), isNull);
    expect(find.text('Nama pengguna atau kata sandi salah. Coba lagi.'), findsOneWidget);
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/auth/login_screen_test.dart`
Expected: FAIL — `LoginScreen` undefined.

- [ ] **Step 4: Write `lib/features/auth/login_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'auth_session.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await ref.read(authSessionProvider.notifier).login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _showError = !success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              key: const Key('loginUsername'),
              controller: _usernameController,
              decoration: InputDecoration(labelText: l10n.usernameLabel),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('loginPassword'),
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: l10n.passwordLabel),
            ),
            const SizedBox(height: 24),
            if (_showError) ...[
              Text(l10n.loginError, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 48,
              child: ElevatedButton(
                key: const Key('loginSubmit'),
                onPressed: _submit,
                child: Text(l10n.loginButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/auth/login_screen_test.dart`
Expected: `00:0X +2: All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_id.arb lib/features/auth/login_screen.dart test/features/auth/login_screen_test.dart
git commit -m "feat(auth): add login screen"
```

---

### Task 7: Wire it into the app entry point

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/features/home/home_screen.dart`
- Modify: `test/features/home/home_screen_test.dart`
- Create: `test/main_auth_gate_test.dart`

- [ ] **Step 1: Add a logout button to the home screen**

Replace the full contents of `lib/features/home/home_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_session.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('logoutButton'),
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authSessionProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(child: Text(l10n.appTitle)),
    );
  }
}
```

- [ ] **Step 2: Update the existing home screen test for the new `ConsumerWidget` type**

Replace the full contents of `test/features/home/home_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/features/auth/auth_session.dart';
import 'package:pharmacy_inventory_platform/features/home/home_screen.dart';
import 'package:pharmacy_inventory_platform/l10n/app_localizations.dart';

void main() {
  testWidgets('renders the app title from localized strings, default locale id',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: HomeScreen(),
        ),
      ),
    );

    expect(find.text('Platform Inventaris Apotek'), findsWidgets);
  });

  testWidgets('logout button clears the session', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    final hash = container.read(passwordHasherProvider).hash('secret123');
    await container.read(userRepositoryProvider).createUser(
          username: 'budi',
          passwordHash: hash,
          role: 'kasir',
        );
    await container.read(authSessionProvider.notifier).login('budi', 'secret123');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('id'),
          home: HomeScreen(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pump();

    expect(container.read(authSessionProvider), isNull);
  });
}
```

- [ ] **Step 3: Write the failing test for the routing gate**

```dart
// test/main_auth_gate_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/core/providers.dart';
import 'package:pharmacy_inventory_platform/data/database.dart';
import 'package:pharmacy_inventory_platform/main.dart';

import 'support/user_repository_test_seed.dart';

void main() {
  testWidgets('shows setup screen when there are no users yet', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const PharmacyInventoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('setupAdminUsername')), findsOneWidget);
  });

  testWidgets('shows login screen when a user already exists', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await UserRepositoryTestSeed(db).seedOneUser();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const PharmacyInventoryApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loginUsername')), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run test to verify it fails**

Run: `flutter test test/main_auth_gate_test.dart`
Expected: FAIL — `UserRepositoryTestSeed` doesn't exist yet (the import added above
resolves to a file that isn't there until Step 5), and `PharmacyInventoryApp` doesn't
route based on user count yet (currently always shows `HomeScreen`).

- [ ] **Step 5: Add a tiny test-only seed helper**

Create `test/support/user_repository_test_seed.dart`:

```dart
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
```

- [ ] **Step 6: Rewrite `lib/main.dart` with the auth gate**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'features/auth/auth_session.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/setup_admin_screen.dart';
import 'features/home/home_screen.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: PharmacyInventoryApp()));
}

class PharmacyInventoryApp extends StatelessWidget {
  const PharmacyInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pharmacy Inventory Platform',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('id'),
      home: const AuthGate(),
    );
  }
}

/// Decides between first-run setup, login, and the logged-in app based on
/// whether any user exists yet and whether one is currently logged in.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authSessionProvider);
    if (currentUser != null) return const HomeScreen();

    final userCount = ref.watch(_userCountProvider);
    return userCount.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(body: Center(child: Text('$error'))),
      data: (count) => count == 0 ? const SetupAdminScreen() : const LoginScreen(),
    );
  }
}

final _userCountProvider = FutureProvider<int>(
  (ref) => ref.watch(userRepositoryProvider).countUsers(),
);
```

- [ ] **Step 7: Run all tests to verify everything passes**

Run: `flutter test`
Expected: all tests pass, including the two new `main_auth_gate_test.dart` cases and
the updated `home_screen_test.dart`.

- [ ] **Step 8: Run analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/main.dart lib/features/home/home_screen.dart test/features/home/home_screen_test.dart test/main_auth_gate_test.dart test/support/user_repository_test_seed.dart
git commit -m "feat(auth): wire login/setup/home routing into the app entry point"
```

---

### Task 8: Push, open PR, get CI green, merge

- [ ] **Step 1: Push the branch**

```bash
git checkout -b feat/auth-roles-foundation
git push -u origin feat/auth-roles-foundation
```

- [ ] **Step 2: Open the PR (title follows the react-spectrum convention)**

```bash
gh pr create --title "feat(auth): login, first-run admin setup, and role permission matrix" --body "$(cat <<'EOF'
## Summary
- Password hashing (bcrypt, pure Dart -- works on both Windows and Android)
- Role permission matrix from design spec section 5, including the
  sold-batch edit restriction (admin-only)
- User repository + audit logger (data layer), reusable by future
  inventory/POS plans
- First-run "create admin account" screen (no other way to provision a user
  on a local-only app) and a login screen
- Auth gate wired into main.dart: no users -> setup screen, users but not
  logged in -> login screen, logged in -> home screen with a logout button

## Test plan
- [ ] CI: analyze-and-test green
- [ ] CI: build-windows green
- [ ] CI: build-android green
EOF
)"
```

- [ ] **Step 3: Watch CI and fix forward until green**

Run: `gh pr checks --watch`
If a check fails: `gh run view <run-id> --log-failed`, fix the specific reported
error, commit, push, re-check. Up to 5 attempts; if still red, stop and report the
exact failing log rather than continuing to guess.

- [ ] **Step 4: Merge**

Run: `gh pr merge --squash --delete-branch`
