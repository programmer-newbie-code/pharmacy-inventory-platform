import 'package:shared_preferences/shared_preferences.dart';

class DriveCredentialStore {
  DriveCredentialStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  static const _clientIdKey = 'google_drive_client_id';
  static const _clientSecretKey = 'google_drive_client_secret';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? await SharedPreferences.getInstance();

  /// Gets stored Client ID.
  Future<String?> getClientId() async {
    final p = await _prefs;
    final val = p.getString(_clientIdKey);
    return (val != null && val.trim().isNotEmpty) ? val.trim() : null;
  }

  /// Gets stored Client Secret.
  Future<String?> getClientSecret() async {
    final p = await _prefs;
    final val = p.getString(_clientSecretKey);
    return (val != null && val.trim().isNotEmpty) ? val.trim() : null;
  }

  /// Saves runtime Google Drive OAuth credentials.
  Future<void> saveCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    final p = await _prefs;
    await p.setString(_clientIdKey, clientId.trim());
    await p.setString(_clientSecretKey, clientSecret.trim());
  }

  /// Checks if both Client ID and Client Secret are configured.
  Future<bool> hasCredentials() async {
    final id = await getClientId();
    final secret = await getClientSecret();
    return id != null && secret != null;
  }

  /// Clears stored Google Drive credentials.
  Future<void> clearCredentials() async {
    final p = await _prefs;
    await p.remove(_clientIdKey);
    await p.remove(_clientSecretKey);
  }
}
