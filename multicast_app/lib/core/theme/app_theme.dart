import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color background = Color(0xFF121212); // Dark slate/charcoal
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);
  static const Color primary = Color(0xFF00E676); // High contrast accent (Green)
  static const Color primaryVariant = Color(0xFF00C853);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color error = Color(0xFFFF5252);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryVariant,
      surface: surface,
      error: error,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: textPrimary,
      onError: Colors.white,
    ),
    useMaterial3: true,
    fontFamily: 'Roboto', // Using default Roboto, can be customized later
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
      displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 28),
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 24),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: primary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: surface,
      selectedIconTheme: IconThemeData(color: primary),
      unselectedIconTheme: IconThemeData(color: textSecondary),
      selectedLabelTextStyle: TextStyle(color: primary),
      unselectedLabelTextStyle: TextStyle(color: textSecondary),
    ),
    cardTheme: CardTheme(
      color: surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
  );
}
