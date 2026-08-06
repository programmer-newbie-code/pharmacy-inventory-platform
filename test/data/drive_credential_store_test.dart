import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pharmacy_inventory_platform/data/drive_credential_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DriveCredentialStore', () {
    test('initially returns null and hasCredentials false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DriveCredentialStore(prefs: prefs);

      expect(await store.getClientId(), isNull);
      expect(await store.getClientSecret(), isNull);
      expect(await store.hasCredentials(), isFalse);
    });

    test('saveCredentials saves trimmed values and hasCredentials returns true',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = DriveCredentialStore(prefs: prefs);

      await store.saveCredentials(
        clientId: '  my_client_id  ',
        clientSecret: '  my_client_secret  ',
      );

      expect(await store.getClientId(), equals('my_client_id'));
      expect(await store.getClientSecret(), equals('my_client_secret'));
      expect(await store.hasCredentials(), isTrue);
    });

    test('clearCredentials removes saved credentials', () async {
      SharedPreferences.setMockInitialValues({
        'google_drive_client_id': 'id123',
        'google_drive_client_secret': 'sec123',
      });
      final prefs = await SharedPreferences.getInstance();
      final store = DriveCredentialStore(prefs: prefs);

      expect(await store.hasCredentials(), isTrue);

      await store.clearCredentials();

      expect(await store.getClientId(), isNull);
      expect(await store.getClientSecret(), isNull);
      expect(await store.hasCredentials(), isFalse);
    });
  });
}
