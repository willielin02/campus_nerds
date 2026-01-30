import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Campus Nerds typography definitions
/// Using Noto Sans TC for Traditional Chinese support
class AppTypography {
  final AppColorsTheme colors;

  const AppTypography({required this.colors});

  static const String fontFamily = 'Noto Sans TC';

  // ============================================
  // Display Styles
  // ============================================
  TextStyle get displayLarge => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 68.0,
      );

  TextStyle get displayMedium => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 56.0,
      );

  TextStyle get displaySmall => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 44.0,
      );

  // ============================================
  // Headline Styles
  // ============================================
  TextStyle get headlineLarge => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 40.0,
      );

  TextStyle get headlineMedium => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 32.0,
      );

  TextStyle get headlineSmall => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 28.0,
      );

  // ============================================
  // Title Styles
  // ============================================
  TextStyle get titleLarge => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 28.0,
      );

  TextStyle get titleMedium => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 24.0,
      );

  TextStyle get titleSmall => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
      );

  // ============================================
  // Label Styles
  // ============================================
  TextStyle get labelLarge => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
      );

  TextStyle get labelMedium => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );

  TextStyle get labelSmall => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  // ============================================
  // Body Styles
  // ============================================
  TextStyle get bodyLarge => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 18.0,
      );

  TextStyle get bodyMedium => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  TextStyle get bodySmall => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );
}

/// Extension for TextStyle to easily override properties
extension TextStyleX on TextStyle {
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
  TextStyle withWeight(FontWeight weight) => copyWith(fontWeight: weight);
  TextStyle withHeight(double height) => copyWith(height: height);

  TextStyle override({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
  }) {
    return copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decoration: decoration,
      height: lineHeight,
      shadows: shadows,
    );
  }
}
