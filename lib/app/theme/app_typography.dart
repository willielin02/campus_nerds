import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Campus Nerds 自訂字體定義
/// 使用 Noto Sans TC，名稱根據實際用途命名
/// 存取方式：context.appTypography.xxx
class AppTypography {
  final AppColorsTheme colors;

  const AppTypography({required this.colors});

  static const String fontFamily = 'Noto Sans TC';

  // ============================================
  // Display / Title — 大型標題（備用）
  // ============================================

  /// 68px w600 — 大型展示文字
  TextStyle get display => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 68.0,
      );

  /// 40px w600 — 大型標題
  TextStyle get title => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 40.0,
      );

  // ============================================
  // Section / Page — 區段與頁面標題
  // ============================================

  /// 28px w600 — 活動類別標題、大型強調數字
  TextStyle get sectionTitle => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 28.0,
      );

  /// 24px w600 — 頁面標題、步驟標題、主要區段標題
  TextStyle get pageTitle => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 24.0,
      );

  // ============================================
  // Heading / Subheading — UI 元件標題
  // ============================================

  /// 20px w600 — Tab 標籤、對話框標題、卡片標題、動作按鈕
  TextStyle get heading => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 20.0,
      );

  /// 20px normal — 次要標籤、CTA 文字、設定項目
  TextStyle get subheading => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 20.0,
      );

  // ============================================
  // Body / Detail — 內文
  // ============================================

  /// 18px normal — 對話框按鈕、內文、個人資料名稱、FAQ
  TextStyle get body => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 18.0,
      );

  /// 16px normal — 對話框內容、表單細節、預訂資訊、規則文字
  TextStyle get detail => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );

  // ============================================
  // Caption / Footnote — 輔助文字
  // ============================================

  /// 14px normal — 描述、metadata、聊天時間戳、次要資訊
  TextStyle get caption => GoogleFonts.notoSansTc(
        color: colors.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  /// 12px normal — 免責聲明、小字印刷、徽章、警告
  TextStyle get footnote => GoogleFonts.notoSansTc(
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
