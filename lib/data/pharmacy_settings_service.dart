import 'package:shared_preferences/shared_preferences.dart';

class PharmacySettings {
  PharmacySettings({
    required this.name,
    required this.address,
    required this.phone,
    this.logoPath,
  });

  final String name;
  final String address;
  final String phone;
  final String? logoPath;

  PharmacySettings copyWith({
    String? name,
    String? address,
    String? phone,
    String? logoPath,
  }) {
    return PharmacySettings(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}

class PharmacySettingsService {
  static const _keyName = 'pharmacy_name';
  static const _keyAddress = 'pharmacy_address';
  static const _keyPhone = 'pharmacy_phone';
  static const _keyLogo = 'pharmacy_logo';

  Future<PharmacySettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return PharmacySettings(
      name: prefs.getString(_keyName) ?? 'Apotek Sehat Pharmacy',
      address: prefs.getString(_keyAddress) ?? 'Jl. Kesehatan No. 123, Jakarta',
      phone: prefs.getString(_keyPhone) ?? '(021) 555-0199',
      logoPath: prefs.getString(_keyLogo),
    );
  }

  Future<void> saveSettings(PharmacySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, settings.name);
    await prefs.setString(_keyAddress, settings.address);
    await prefs.setString(_keyPhone, settings.phone);
    if (settings.logoPath != null) {
      await prefs.setString(_keyLogo, settings.logoPath!);
    } else {
      await prefs.remove(_keyLogo);
    }
  }
}
