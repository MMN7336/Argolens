import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'Myanmar'; // Default

  String get currentLanguage => _currentLanguage;
  bool get isMyanmar => _currentLanguage == 'Myanmar';

  LanguageProvider() {
    _loadLanguage();
  }

  // SharedPreferences ထဲက သိမ်းထားတာကို ဖတ်ရန်
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'Myanmar';
    notifyListeners();
  }

  // ဘာသာစကားပြောင်းပြီး App တစ်ခုလုံးကို အကြောင်းကြားရန်
  Future<void> setLanguage(String lang) async {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', lang);
    notifyListeners();
  }
}