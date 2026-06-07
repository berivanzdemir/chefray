import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı auth tercihlerini (Beni Hatırla vb.) kalıcı depolamaya yazar/okur.
class AuthPreferencesService {
  AuthPreferencesService._();
  static final AuthPreferencesService instance = AuthPreferencesService._();

  static const _keyRememberMe = 'auth_remember_me';

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, value);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
  }
}
