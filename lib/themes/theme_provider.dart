import 'package:flutter/material.dart';
import 'package:attendify/themes/dark_mode.dart';
import 'package:attendify/themes/light_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Theme storage key
  static const String themeKey = 'theme_mode';

  // Initializing Light-Mode by default
  ThemeData _themeData = lightMode;

  // Get Current Theme
  ThemeData get themeData => _themeData;
  bool get isDarkMode => _themeData == darkMode;

  // Initialize theme provider and load saved theme
  ThemeProvider() {
    loadTheme();
  }

  // Load saved theme from SharedPreferences
  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isDark = prefs.getBool(themeKey) ?? false; // Default to light mode
    _themeData = isDark ? darkMode : lightMode;
    notifyListeners();
  }

  // Save theme to SharedPreferences
  Future<void> _saveTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(themeKey, isDark);
  }

  // Set Theme
  set themeData(ThemeData themeData) {
    _themeData = themeData;
    _saveTheme(_themeData == darkMode);
    notifyListeners();
  }

  // Toggle Themes
  void toggleTheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}