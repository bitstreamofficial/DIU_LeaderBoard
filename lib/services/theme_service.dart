import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = true;

  // Color constants for more consistent theming
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _lightBackground = Color(0xFFF5F5F5);
  static const Color _primaryDark = Color(0xFF2B2E4A);
  static const Color _primaryLight = Colors.blueGrey;

  // Add your specific colors
  static const Color _cardColorDark = Color(0xFF262626);
  static const Color _cardColorLight = Color(0xFFFFFBF5);
  static const Color _selectedItemColor = Color.fromARGB(255, 83, 167, 114);

  ThemeService() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode ? darkTheme : lightTheme;
  }

  static final darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: _darkBackground,
    primaryColor: _primaryDark,
    cardColor: _cardColorDark,
    colorScheme: ColorScheme.dark(
      primary: _primaryDark,
      secondary: _selectedItemColor,
      surface: _cardColorDark,
      background: _darkBackground,
      tertiary: _selectedItemColor,
      onBackground: Colors.white,
      onSurface: Colors.white,
      onPrimary: Colors.black,
      onSecondary: Colors.white,
      
      
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkBackground,
      indicatorColor: _selectedItemColor,
    ),
    textTheme: ThemeData.dark()
        .textTheme
        .apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        )
        .copyWith(
          bodyLarge: const TextStyle(color: Colors.white),
          bodyMedium: const TextStyle(color: Colors.white),
          titleMedium: const TextStyle(color: Colors.white),
          titleSmall: TextStyle(color: Colors.grey[300]),
          labelLarge: const TextStyle(color: Colors.white),
        ),
  );

  static final lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: _lightBackground,
    primaryColor: _primaryLight,
    cardColor: _cardColorLight,
    colorScheme: ColorScheme.light(
      primary: _primaryLight,
      secondary: _selectedItemColor,
      surface: _cardColorLight,
      background: Colors.grey[200],
      tertiary: _selectedItemColor,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color.fromARGB(255, 82, 184, 120),
    ),
    textTheme: ThemeData.light()
        .textTheme
        .apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        )
        .copyWith(
          bodyLarge: const TextStyle(color: Colors.black87),
          bodyMedium: const TextStyle(color: Colors.black87),
          titleMedium: const TextStyle(color: Colors.black87),
          titleSmall: TextStyle(color: Colors.grey[800]),
          labelLarge: const TextStyle(color: Colors.black87),
        ),
  );
}
