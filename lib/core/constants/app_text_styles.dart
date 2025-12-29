import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography styles matching Baret Scholars brand
/// Reference: Founders Grotesk Condensed from website
/// Flutter alternative: Roboto Condensed
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  /// Base font family - Roboto Condensed (similar to Founders Grotesk Condensed)
  static const String _fontFamily = 'RobotoCondensed';

  /// Letter spacing for buttons (from website: 2.2px)
  static const double buttonLetterSpacing = 2.2;

  // ==================
  // HEADING STYLES
  // ==================

  /// H1 - Large headings
  static TextStyle h1 = GoogleFonts.robotoCondensed(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
    height: 1.2,
  );

  /// H2 - Section headings
  static TextStyle h2 = GoogleFonts.robotoCondensed(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
    height: 1.3,
  );

  /// H3 - Subsection headings
  static TextStyle h3 = GoogleFonts.robotoCondensed(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    height: 1.4,
  );

  /// H4 - Card titles
  static TextStyle h4 = GoogleFonts.robotoCondensed(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    height: 1.4,
  );

  // ==================
  // BODY STYLES
  // ==================

  /// Body Large - Primary body text
  static TextStyle bodyLarge = GoogleFonts.robotoCondensed(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
    height: 1.6,
  );

  /// Body Medium - Secondary body text
  static TextStyle bodyMedium = GoogleFonts.robotoCondensed(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.black,
    height: 1.5,
  );

  /// Body Small - Tertiary body text
  static TextStyle bodySmall = GoogleFonts.robotoCondensed(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textGray,
    height: 1.5,
  );

  // ==================
  // BUTTON STYLES
  // ==================

  /// Button text - with characteristic letter spacing
  static TextStyle button = GoogleFonts.robotoCondensed(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: buttonLetterSpacing,
    color: AppColors.white,
  );

  /// Button text small
  static TextStyle buttonSmall = GoogleFonts.robotoCondensed(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: buttonLetterSpacing,
    color: AppColors.white,
  );

  // ==================
  // SPECIAL STYLES
  // ==================

  /// Caption - Small annotations
  static TextStyle caption = GoogleFonts.robotoCondensed(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textGray,
    height: 1.4,
  );

  /// Label - Input labels
  static TextStyle label = GoogleFonts.robotoCondensed(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textGray,
    height: 1.4,
  );

  /// Overline - Small uppercase text
  static TextStyle overline = GoogleFonts.robotoCondensed(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.textGray,
  );

  // ==================
  // GLOBE SPECIFIC
  // ==================

  /// Alumni name on marker popup
  static TextStyle alumniName = GoogleFonts.robotoCondensed(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    height: 1.3,
  );

  /// Location text on marker popup
  static TextStyle locationText = GoogleFonts.robotoCondensed(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.white,
    height: 1.4,
  );

  /// Cohort badge text
  static TextStyle cohortBadge = GoogleFonts.robotoCondensed(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: AppColors.white,
  );
}
