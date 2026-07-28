import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/pharmacy_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('getSettings returns default values when uninitialized', () async {
    final service = PharmacySettingsService();
    final settings = await service.getSettings();

    expect(settings.name, 'Apotek Sehat Pharmacy');
    expect(settings.address, contains('Jl. Kesehatan'));
    expect(settings.phone, contains('021'));
    expect(settings.logoPath, isNull);
  });

  test('saveSettings persists custom values', () async {
    final service = PharmacySettingsService();
    await service.saveSettings(
      PharmacySettings(
        name: 'Apotek Medika Utama',
        address: 'Jl. Sudirman No. 10',
        phone: '08123456789',
        logoPath: '/path/to/logo.png',
      ),
    );

    final settings = await service.getSettings();
    expect(settings.name, 'Apotek Medika Utama');
    expect(settings.address, 'Jl. Sudirman No. 10');
    expect(settings.phone, '08123456789');
    expect(settings.logoPath, '/path/to/logo.png');
  });
}
