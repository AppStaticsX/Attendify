import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String authKey = 'isAuthenticated';

  // Save authentication state
  static Future<void> saveAuthState(bool isAuthenticated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(authKey, isAuthenticated);
  }

  // Load authentication state
  static Future<bool> getAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(authKey) ?? false;
  }

  // Clear authentication state
  static Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(authKey);
  }
}