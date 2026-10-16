import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final String _key = "isDarkMode";
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  // App ဖွင့်တိုင်း ယခင်ရွေးခဲ့သော Theme ကို ဖတ်ယူခြင်း
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  // Theme ကို ပြောင်းလဲပြီး SharedPreferences ထဲ သိမ်းဆည်းခြင်း
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDarkMode);
  }

  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  // Premium Dark Theme
  final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E), // Dark Card Color
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D5A27),
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
    ),
  );

  // Premium Light Theme
  final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF9F7F2),
    cardColor: Colors.white, // Light Card Color
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2D5A27),
      brightness: Brightness.light,
      surface: const Color(0xFFF9F7F2),
    ),
  );
}