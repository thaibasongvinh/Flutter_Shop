import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  // Tải cấu hình theme từ bộ nhớ máy
  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  // Chuyển đổi qua lại giữa Sáng và Tối
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Cấu hình màu sắc cho Theme Sáng
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xffeff1f7),
        primaryColor: const Color(0xff568A9F),
        colorScheme: const ColorScheme.light(
          primary: Color(0xff568A9F),
          secondary: Color(0xff579f8c),
        ),
      );

  // Cấu hình màu sắc cho Theme Tối
  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff121212),
        primaryColor: const Color(0xff568A9F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff568A9F),
          surface: Color(0xff1e1e1e),
        ),
      );
}
