// lib/core/theme/app_text_styles.dart
//
// Single source of truth for every text style in the app.
//
// Usage:
//   Text('Hello', style: AppTextStyles.heading(isDark))
//   Text('Sub', style: AppTextStyles.caption(isDark))
//   Text('EzzeWash', style: AppTextStyles.brandLogo)
//
// All styles use the Alexandria font (set globally in AppTheme) via
// GoogleFonts.alexandria so they remain consistent with the theme.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_color.dart';

abstract class AppTextStyles {
  AppTextStyles._();

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static Color _text(bool isDark) =>
      isDark ? AppColors.darkText : AppColors.lightText;

  static Color _sub(bool isDark) =>
      isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

  // ─── Brand / Logo ──────────────────────────────────────────────────────────

  /// App logo — Pacifico, white, 20 sp.
  static TextStyle get brandLogo => TextStyle(
    fontFamily: GoogleFonts.pacifico().fontFamily,
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.1,
  );

  // ─── Headings ──────────────────────────────────────────────────────────────

  /// Page / section heading — 20 sp bold.
  static TextStyle heading(bool isDark) => GoogleFonts.alexandria(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: _text(isDark),
  );

  /// H4 heading — 16 sp w600.
  static TextStyle h4(bool isDark) => GoogleFonts.alexandria(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: _text(isDark),
  );

  /// Section heading — 18 sp w700 (home sections, card titles).
  static TextStyle sectionTitle(bool isDark) => GoogleFonts.alexandria(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: _text(isDark),
  );

  /// Card / list item title — 15 sp bold.
  static TextStyle cardTitle(bool isDark) => GoogleFonts.alexandria(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: _text(isDark),
  );

  /// Order number / row title — 14 sp w700.
  static TextStyle rowTitle(bool isDark) => GoogleFonts.alexandria(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: _text(isDark),
  );

  /// Service card grid title — 13 sp w600.
  static TextStyle gridTitle(bool isDark) => GoogleFonts.alexandria(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: _text(isDark),
  );

  // ─── Body ──────────────────────────────────────────────────────────────────

  /// Standard body copy — 14 sp regular.
  static TextStyle body(bool isDark) =>
      GoogleFonts.alexandria(fontSize: 14, color: _text(isDark));

  /// Body medium weight — 14 sp w500.
  static TextStyle bodyMedium(bool isDark) => GoogleFonts.alexandria(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _text(isDark),
  );

  /// Body with explicit line-height for multi-line paragraphs.
  static TextStyle bodyLong(bool isDark) => GoogleFonts.alexandria(
    fontSize: 14,
    height: 1.5,
    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
  );

  // ─── Labels & subtexts ────────────────────────────────────────────────────

  /// Sub-label under a title — 12 sp regular.
  static TextStyle subtitle(bool isDark) =>
      GoogleFonts.alexandria(fontSize: 12, color: _sub(isDark));

  /// Small captions, meta info — 11 sp regular.
  static TextStyle caption(bool isDark) =>
      GoogleFonts.alexandria(fontSize: 11, color: _sub(isDark));

  /// Caption with medium weight — 11 sp w500.
  static TextStyle captionMedium(bool isDark) => GoogleFonts.alexandria(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: _sub(isDark),
  );

  /// Tiny label — 10 sp, subtext color.
  static TextStyle tiny(bool isDark) =>
      GoogleFonts.alexandria(fontSize: 10, color: _sub(isDark));

  // ─── Interactive ──────────────────────────────────────────────────────────

  /// "View All" / link text — 13 sp w600 primary color.
  static TextStyle link = GoogleFonts.alexandria(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  /// Button label — 15 sp bold white.
  static TextStyle button = GoogleFonts.alexandria(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// Small button / chip label — 12 sp w600 white.
  static TextStyle buttonSmall = GoogleFonts.alexandria(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// Outline button label — 14 sp w600 primary color.
  static TextStyle buttonOutline = GoogleFonts.alexandria(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  // ─── Prices ───────────────────────────────────────────────────────────────

  /// Price tag — 12 sp w700 primary color.
  static TextStyle price = GoogleFonts.alexandria(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /// Large price — 18 sp bold primary color.
  static TextStyle priceLarge = GoogleFonts.alexandria(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // ─── Status / badges ──────────────────────────────────────────────────────

  /// Status badge text — 9 sp bold, accepts explicit color.
  static TextStyle statusBadge(Color color) => GoogleFonts.alexandria(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: color,
  );

  /// Larger status label — 11 sp w600, accepts explicit color.
  static TextStyle statusLabel(Color color) => GoogleFonts.alexandria(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: color,
  );

  // ─── Rating ───────────────────────────────────────────────────────────────

  static const Color _starColor = Color(0xFFFBBF24);

  /// Rating number — 11 sp bold amber.
  static TextStyle rating = GoogleFonts.alexandria(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: _starColor,
  );

  // ─── On-gradient (white) ──────────────────────────────────────────────────

  /// Text on gradient backgrounds — 15 sp bold white.
  static TextStyle onGradientTitle = GoogleFonts.alexandria(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  /// Sub-info on gradient — 11 sp white70.
  static TextStyle onGradientSub = GoogleFonts.alexandria(
    fontSize: 11,
    color: Colors.white70,
  );

  /// App bar title on gradient — 20 sp bold white.
  static TextStyle appBarTitle = GoogleFonts.alexandria(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // ─── Input ────────────────────────────────────────────────────────────────

  /// Text field input text — 14 sp.
  static TextStyle input = GoogleFonts.alexandria(fontSize: 14);

  /// Text field hint — 14 sp grey.
  static TextStyle hint(bool isDark) => GoogleFonts.alexandria(
    fontSize: 14,
    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
  );

  // ─── Navigation ───────────────────────────────────────────────────────────

  /// Bottom nav label — 11 sp, color injected by caller.
  static TextStyle navLabel(Color color, {bool selected = false}) =>
      GoogleFonts.alexandria(
        fontSize: 11,
        letterSpacing: 0.2,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: color,
      );
}
