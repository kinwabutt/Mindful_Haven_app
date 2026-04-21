import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Constructor jo app start hote hi purana theme load karega
  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool value) async {
    _isDarkMode = value;
    notifyListeners();

    // Disk par save karna taake app band hone pe na bhoolay
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Agar pehle se koi value save hai to wo le lo, warna false (Light mode)
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
}
