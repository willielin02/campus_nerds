import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'app_typography.dart';

export 'app_colors.dart';

const String _kThemeModeKey = '__theme_mode__';

/// Campus Nerds Theme Manager
/// Handles theme persistence and provides theme data
class AppTheme {
  static SharedPreferences? _prefs;

  /// Initialize theme system (call in main before runApp)
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get current theme mode from storage
  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(_kThemeModeKey);
    if (darkMode == null) return ThemeMode.system;
    return darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Save theme mode to storage
  static Future<void> saveThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      await _prefs?.remove(_kThemeModeKey);
    } else {
      await _prefs?.setBool(_kThemeModeKey, mode == ThemeMode.dark);
    }
  }

  /// Get light theme data
  static ThemeData get lightTheme {
    final colors = AppColorsTheme(isDark: false);
    return _buildTheme(colors, Brightness.light);
  }

  /// Get dark theme data
  static ThemeData get darkTheme {
    final colors = AppColorsTheme(isDark: true);
    return _buildTheme(colors, Brightness.dark);
  }

  static ThemeData _buildTheme(AppColorsTheme colors, Brightness brightness) {
    final typography = AppTypography(colors: colors);

    return ThemeData(
      brightness: brightness,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.primaryBackground,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.primaryText,
        secondary: colors.secondary,
        onSecondary: colors.primaryText,
        tertiary: colors.tertiary,
        onTertiary: colors.primaryText,
        error: colors.error,
        onError: Colors.white,
        surface: colors.secondaryBackground,
        onSurface: colors.primaryText,
      ),
      textTheme: TextTheme(
        displayLarge: typography.displayLarge,
        displayMedium: typography.displayMedium,
        displaySmall: typography.displaySmall,
        headlineLarge: typography.headlineLarge,
        headlineMedium: typography.headlineMedium,
        headlineSmall: typography.headlineSmall,
        titleLarge: typography.titleLarge,
        titleMedium: typography.titleMedium,
        titleSmall: typography.titleSmall,
        labelLarge: typography.labelLarge,
        labelMedium: typography.labelMedium,
        labelSmall: typography.labelSmall,
        bodyLarge: typography.bodyLarge,
        bodyMedium: typography.bodyMedium,
        bodySmall: typography.bodySmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primaryBackground,
        foregroundColor: colors.primaryText,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: colors.secondaryBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.primaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.alternate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.alternate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.error),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.alternate,
        thickness: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.secondaryBackground,
        selectedItemColor: colors.primaryText,
        unselectedItemColor: colors.secondaryText,
      ),
    );
  }
}

/// Extension to easily access theme colors and typography from BuildContext
extension AppThemeX on BuildContext {
  /// Get current theme data
  ThemeData get theme => Theme.of(this);

  /// Get current color scheme
  ColorScheme get colorScheme => theme.colorScheme;

  /// Get current text theme
  TextTheme get textTheme => theme.textTheme;

  /// Get app-specific colors based on current brightness
  AppColorsTheme get appColors {
    final isDark = theme.brightness == Brightness.dark;
    return AppColorsTheme(isDark: isDark);
  }

  /// Get app-specific typography based on current brightness
  AppTypography get appTypography {
    return AppTypography(colors: appColors);
  }

  /// Check if dark mode is active
  bool get isDarkMode => theme.brightness == Brightness.dark;
}
