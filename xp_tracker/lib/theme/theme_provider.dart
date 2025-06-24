import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Handles theme switching
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
}