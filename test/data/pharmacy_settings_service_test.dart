import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacy_inventory_platform/data/pharmacy_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('PharmacySettings copyWith and Service save/get settings', () async {
    SharedPreferences.setMockInitialValues({});
    final service = PharmacySettingsService();

    final initial = await service.getSettings();
    expect(initial.name, 'Apotek Sehat Pharmacy');
    expect(initial.logoPath, isNull);

    final updated = initial.copyWith(
      name: 'Apotek Mandiri',
      address: 'Jl. Merdeka 45',
      phone: '08123456789',
      logoPath: '/tmp/logo.png',
    );

    await service.saveSettings(updated);

    final loaded = await service.getSettings();
    expect(loaded.name, 'Apotek Mandiri');
    expect(loaded.address, 'Jl. Merdeka 45');
    expect(loaded.phone, '08123456789');
    expect(loaded.logoPath, '/tmp/logo.png');

    // Test removing logo
    final noLogo = loaded.copyWith(logoPath: null);
    await service.saveSettings(PharmacySettings(
      name: noLogo.name,
      address: noLogo.address,
      phone: noLogo.phone,
      logoPath: null,
    ));

    final reloaded = await service.getSettings();
    expect(reloaded.logoPath, isNull);
  });
}
