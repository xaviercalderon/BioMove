// services/theme_service.dart — Modo claro/oscuro
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _i = ThemeService._();
  factory ThemeService() => _i;
  ThemeService._();

  bool _isDark = true;
  bool get isDark => _isDark;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('is_dark_mode') ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDark);
    notifyListeners();
  }

  ThemeData get theme => _isDark ? _darkTheme : _lightTheme;

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF07070F),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6C63FF), secondary: Color(0xFF00D4AA),
      error: Color(0xFFFF5252), surface: Color(0xFF161624),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D0D1A), elevation: 0,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(color: Colors.white,
          fontSize: 18, fontWeight: FontWeight.w700),
    ),
    cardColor: const Color(0xFF161624),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFF1E1E2E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      labelStyle: const TextStyle(color: Color(0xFF888899)),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Color(0xFF888899)),
    ),
  );

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5F5FA),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6C63FF), secondary: Color(0xFF00B896),
      error: Color(0xFFE53935), surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, elevation: 0,
      foregroundColor: Color(0xFF1A1A2E),
      titleTextStyle: TextStyle(color: Color(0xFF1A1A2E),
          fontSize: 18, fontWeight: FontWeight.w700),
    ),
    cardColor: Colors.white,
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: const Color(0xFFF0F0F8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      labelStyle: const TextStyle(color: Color(0xFF666677)),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1A1A2E)),
      bodySmall: TextStyle(color: Color(0xFF666677)),
    ),
  );
}
