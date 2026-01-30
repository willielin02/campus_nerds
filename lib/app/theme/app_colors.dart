import 'package:flutter/material.dart';

/// Campus Nerds app color palette
/// Extracted from FlutterFlow theme and cleaned up
abstract class AppColors {
  // ============================================
  // Light Mode Colors
  // ============================================
  static const Color lightPrimary = Color(0xFFFBFBFF);
  static const Color lightSecondary = Color(0xFFFFFFFF);
  static const Color lightTertiary = Color(0xFFDBDBDD);
  static const Color lightAlternate = Color(0xFFEEEEF1);
  static const Color lightPrimaryText = Color(0xFF14181B);
  static const Color lightSecondaryText = Color(0xFF57636C);
  static const Color lightTertiaryText = Color(0xFF9AA6AF);
  static const Color lightQuaternary = Color(0xFFBBC1C6);
  static const Color lightPrimaryBackground = Color(0xFFFBFBFF);
  static const Color lightSecondaryBackground = Color(0xFFFFFFFF);
  static const Color lightAccent1 = Color(0x4C4B39EF);
  static const Color lightAccent2 = Color(0x4D39D2C0);
  static const Color lightAccent3 = Color(0x4DEE8B60);
  static const Color lightAccent4 = Color(0xCCFFFFFF);

  // ============================================
  // Dark Mode Colors
  // ============================================
  static const Color darkPrimary = Color(0xFF4B39EF);
  static const Color darkSecondary = Color(0xFF39D2C0);
  static const Color darkTertiary = Color(0xFFEE8B60);
  static const Color darkAlternate = Color(0xFF262D34);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFF95A1AC);
  static const Color darkTertiaryText = Color(0xFF546189);
  static const Color darkQuaternary = Color(0xFF0551BE);
  static const Color darkPrimaryBackground = Color(0xFF1D2428);
  static const Color darkSecondaryBackground = Color(0xFF14181B);
  static const Color darkAccent1 = Color(0x4C4B39EF);
  static const Color darkAccent2 = Color(0x4D39D2C0);
  static const Color darkAccent3 = Color(0x4DEE8B60);
  static const Color darkAccent4 = Color(0xB2262D34);

  // ============================================
  // Semantic Colors (shared across themes)
  // ============================================
  static const Color success = Color(0xFF249689);
  static const Color warning = Color(0xFFF9CF58);
  static const Color error = Color(0xFFFF5963);
  static const Color info = Color(0xFFFFFFFF);
}

/// Extension to provide theme-aware colors
class AppColorsTheme {
  final bool isDark;

  const AppColorsTheme({required this.isDark});

  Color get primary => isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
  Color get secondary => isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
  Color get tertiary => isDark ? AppColors.darkTertiary : AppColors.lightTertiary;
  Color get alternate => isDark ? AppColors.darkAlternate : AppColors.lightAlternate;
  Color get primaryText => isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
  Color get secondaryText => isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
  Color get tertiaryText => isDark ? AppColors.darkTertiaryText : AppColors.lightTertiaryText;
  Color get quaternary => isDark ? AppColors.darkQuaternary : AppColors.lightQuaternary;
  Color get primaryBackground => isDark ? AppColors.darkPrimaryBackground : AppColors.lightPrimaryBackground;
  Color get secondaryBackground => isDark ? AppColors.darkSecondaryBackground : AppColors.lightSecondaryBackground;
  Color get accent1 => isDark ? AppColors.darkAccent1 : AppColors.lightAccent1;
  Color get accent2 => isDark ? AppColors.darkAccent2 : AppColors.lightAccent2;
  Color get accent3 => isDark ? AppColors.darkAccent3 : AppColors.lightAccent3;
  Color get accent4 => isDark ? AppColors.darkAccent4 : AppColors.lightAccent4;

  // Semantic colors
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get error => AppColors.error;
  Color get info => AppColors.info;
}
