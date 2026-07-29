# Backup Integrity and Google Drive Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make backup/restore complete, validated, atomic, testable, and usable on Windows and Android without production mock paths.

**Architecture:** Introduce a versioned backup envelope and validator in the data layer. Split Google authorization and Drive transport behind injectable collaborators so tests use fakes. Keep orchestration in `BackupService`; keep platform selection and state presentation in the backup feature.

**Tech Stack:** Flutter, Dart, drift, Riverpod, `google_sign_in`, `http`, `file_picker`, ARB localization.

---

## File map

- Create `lib/data/backup_document.dart`: versioned envelope parsing and validation.
- Create `lib/data/drive_upload_client.dart`: Drive transport abstraction and HTTP implementation.
- Modify `lib/data/backup_service.dart`: complete export, preview, validation, atomic restore.
- Modify `lib/data/google_drive_backup_service.dart`: remove mock branches and delegate transport.
- Modify `lib/core/providers.dart`: production dependency wiring.
- Modify `lib/features/backup/backup_screen.dart`: file picker, account state, preview and results.
- Modify `lib/l10n/app_en.arb`, `lib/l10n/app_id.arb`: all backup copy.
- Modify `pubspec.yaml`: add `file_picker`.
- Modify existing backup tests and create validator/transport tests.

### Task 1: Add versioned backup document and validation

**Files:**
- Create: `lib/data/backup_document.dart`
- Create: `test/data/backup_document_test.dart`

- [ ] **Step 1: Write failing tests**

Cover valid version 2 parsing, version 1 normalization, missing collection,
unsupported version, malformed count, and broken foreign-key references.

```dart
test('rejects product references to missing storage locations', () {
  final json = validBackupJson(
    products: [{'id': 8, 'storageLocationId': 99}],
    storageLocations: [],
  );
  expect(
    () => BackupDocument.parseAndValidate(json),
    throwsA(isA<BackupValidationException>()),
  );
});
```

- [ ] **Step 2: Run the focused test**

Run: `flutter test test/data/backup_document_test.dart`

Expected: FAIL because `BackupDocument` does not exist.

- [ ] **Step 3: Implement the document**

Use these public types:

```dart
class BackupValidationException implements Exception {
  BackupValidationException(this.message);
  final String message;
}

class BackupDocument {
  BackupDocument({
    required this.schemaVersion,
    required this.createdAt,
    required this.data,
  });

  static const currentSchemaVersion = 2;
  final int schemaVersion;
  final DateTime createdAt;
  final Map<String, List<Map<String, Object?>>> data;

  static BackupDocument parseAndValidate(String source) {
    // Decode, normalize v1, require every collection, verify IDs/FKs.
  }
}
```

Required collections are exactly those listed in the design spec. Validation
must finish before any database method is called.

- [ ] **Step 4: Verify**

Run: `flutter test test/data/backup_document_test.dart`

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/backup_document.dart test/data/backup_document_test.dart
git commit -m "feat(backup): validate versioned backup documents"
```

### Task 2: Export and restore every business table

**Files:**
- Modify: `lib/data/backup_service.dart`
- Modify: `test/data/backup_service_test.dart`

- [ ] **Step 1: Add failing round-trip test**

Seed one linked record in every table, export, clear, restore, then assert each
table contains its seeded row. Assert `schemaVersion == 2` and the declared
counts equal actual list lengths.

- [ ] **Step 2: Verify failure**

Run: `flutter test test/data/backup_service_test.dart`

Expected: FAIL because suppliers, purchase orders, shifts, and audit records are
not exported/restored.

- [ ] **Step 3: Implement full export**

Export these collections in dependency order:

```text
users
storageLocations
products
stockBatches
saleTransactions
saleItems
auditLogs
backupLogs
cashierShifts
suppliers
purchaseOrders
purchaseOrderItems
```

Build the JSON envelope only after all selects succeed.

- [ ] **Step 4: Implement atomic restore**

Call `BackupDocument.parseAndValidate` before `_db.transaction`. Inside the
transaction, delete children before parents and insert parents before children.
Do not delete or restore `backupLogs` until the rest succeeds; append the
restore-success log after the transaction commits.

- [ ] **Step 5: Verify rollback**

Add a test containing a duplicate unique key halfway through restore. Expected:
restore throws and all original rows remain.

Run: `flutter test test/data/backup_service_test.dart`

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/data/backup_service.dart test/data/backup_service_test.dart
git commit -m "fix(backup): preserve all business data during restore"
```

### Task 3: Remove production mock paths

**Files:**
- Create: `lib/data/drive_upload_client.dart`
- Create: `test/data/drive_upload_client_test.dart`
- Modify: `lib/data/google_drive_backup_service.dart`
- Modify: `test/data/google_drive_backup_service_test.dart`
- Modify: `lib/core/providers.dart`

- [ ] **Step 1: Write failing transport tests**

Use an injected `http.Client` to assert multipart metadata, authorization header,
file bytes, success ID parsing, and safe error mapping.

- [ ] **Step 2: Define collaborators**

```dart
abstract interface class DriveUploadClient {
  Future<String> upload({
    required String accessToken,
    required String fileName,
    required List<int> bytes,
  });
}

abstract interface class GoogleAccountAuthorizer {
  Future<GoogleAccountUser?> signIn();
  Future<void> signOut();
}
```

Production implementations contain no `isMock`, `test_token`, `mock_`, or
simulated-success conditions.

- [ ] **Step 3: Rewrite service tests with fakes**

Test fakes live under `test/support/` and return deterministic user/token/file ID.
They must not be imported by any file under `lib/`.

- [ ] **Step 4: Verify mock removal**

Run:

```bash
rg -n "isMock|test_token|mock_drive_token|simulate" lib
flutter test test/data/google_drive_backup_service_test.dart test/data/drive_upload_client_test.dart
```

Expected: `rg` returns no matches; tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/data/drive_upload_client.dart lib/data/google_drive_backup_service.dart lib/core/providers.dart test/data/drive_upload_client_test.dart test/data/google_drive_backup_service_test.dart test/support
git commit -m "refactor(backup): isolate Google Drive test doubles"
```

### Task 4: Add file selection and restore preview

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`
- Modify: `lib/features/backup/backup_screen.dart`
- Modify: `lib/data/backup_service.dart`
- Modify: `test/features/backup/backup_screen_test.dart`

- [ ] **Step 1: Add dependency**

Run: `flutter pub add file_picker`

- [ ] **Step 2: Add preview API**

```dart
Future<BackupPreview> previewBackupJson(String filePath);

class BackupPreview {
  const BackupPreview({
    required this.createdAt,
    required this.schemaVersion,
    required this.counts,
  });
  final DateTime createdAt;
  final int schemaVersion;
  final Map<String, int> counts;
}
```

- [ ] **Step 3: Add failing widget tests**

Inject a file-selection callback into `BackupScreen`. Test cancel, invalid file,
valid preview, confirmation, successful restore, and rollback failure message.

- [ ] **Step 4: Implement selection flow**

Use `FilePicker.platform.pickFiles` with `allowedExtensions: ['json']`. Show
backup date, products, batches, sales, suppliers, and users before enabling
“Restore data”. Never ask users to type a path.

- [ ] **Step 5: Verify**

Run: `flutter test test/features/backup/backup_screen_test.dart`

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/backup_service.dart lib/features/backup/backup_screen.dart test/features/backup/backup_screen_test.dart
git commit -m "feat(backup): preview and select restore files"
```

### Task 5: Localize and clarify backup states

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_id.arb`
- Modify: `lib/features/backup/backup_screen.dart`
- Modify: `test/features/backup/backup_screen_test.dart`

- [ ] **Step 1: Add ARB keys**

Add copy for disconnected/connected account, connecting, uploading, last
success, retry, file invalid, version unsupported, preview labels, partial
failure, and restore success. Indonesian is default.

- [ ] **Step 2: Replace hardcoded strings**

Map technical failures to plain actions:

```text
401/403 → "Akses Google Drive berakhir. Hubungkan akun lagi."
network → "Tidak ada koneksi. Cadangan lokal tetap aman; coba unggah lagi."
validation → "Berkas bukan cadangan yang didukung. Pilih berkas lain."
```

- [ ] **Step 3: Verify both locales**

Run:

```bash
flutter gen-l10n
flutter test test/features/backup/backup_screen_test.dart
```

Expected: tests pass for `Locale('id')` and `Locale('en')`.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n lib/features/backup/backup_screen.dart test/features/backup/backup_screen_test.dart
git commit -m "localize(backup): explain account and restore states"
```

### Task 6: Full verification and PR

- [ ] Run `dart run build_runner build --delete-conflicting-outputs`.
- [ ] Run `flutter analyze`.
- [ ] Run `flutter test --coverage`.
- [ ] Run `flutter build windows --release`.
- [ ] Run `flutter build apk --release`.
- [ ] Search production code:

```bash
rg -n -i "mock|fake|test_token|dummy|simulate" lib
```

Expected: no production test bypasses.

- [ ] Push `fix/backup-integrity-drive-hardening`.
- [ ] Create PR titled `fix(backup): harden complete backup and restore flow`.
- [ ] Watch all CI checks, fix forward, squash merge only when green.
- [ ] Verify main CI, then create the next patch release tag.
