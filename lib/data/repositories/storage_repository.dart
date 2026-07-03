import 'package:shared_preferences/shared_preferences.dart';

/// Repositorio para persistir datos locales simples (Tokens, Session, etc.).
class StorageRepository {
  final SharedPreferences _prefs;

  StorageRepository(this._prefs);

  static const _keyToken = 'auth_token';
  static const _keyUserId = 'user_id';
  static const _keyUserRole = 'user_role';
  static const _keyThemeMode = 'theme_mode';

  Future<void> saveSession({required String token, required int userId, required String role}) async {
    await _prefs.setString(_keyToken, token);
    await _prefs.setInt(_keyUserId, userId);
    await _prefs.setString(_keyUserRole, role);
  }

  Future<void> clearSession() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserRole);
  }

  String? getToken() => _prefs.getString(_keyToken);
  int? getUserId() => _prefs.getInt(_keyUserId);
  String? getUserRole() => _prefs.getString(_keyUserRole);
  bool isLoggedIn() => getToken() != null;

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'dark';
}
