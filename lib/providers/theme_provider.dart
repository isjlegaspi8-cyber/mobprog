import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  static const Color primaryNavy = Color(0xFF1F3F5F);
  static const Color accentGold = Color(0xFFF5D76E);
  static const Color lightBg = Color(0xFFF4F5F7);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkBg = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1E2A3A);

  bool _isDark = false;
  bool get isDark => _isDark;

  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryNavy,
        scaffoldBackgroundColor: lightBg,
        colorScheme: const ColorScheme.light(
          primary: primaryNavy,
          secondary: accentGold,
          surface: lightCard,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Color(0xFF1F2937),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: lightCard,
          elevation: 2,
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGold,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryNavy,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: primaryNavy,
          secondary: accentGold,
          surface: darkCard,
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: const CardThemeData(
          color: darkCard,
          elevation: 2,
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentGold,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
        ),
      );

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
