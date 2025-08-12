import 'package:flutter/material.dart';
import 'package:ksrtc_users/theme/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme =>
      _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    AppTheme.isDarkMode = _isDarkMode;
    notifyListeners();
  }
}
