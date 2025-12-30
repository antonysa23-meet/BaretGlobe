import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography styles matching Baret Scholars brand
/// Using Guyot Headline font
class AppTextStyles {
  AppTextStyles._(); // Private constructor

  /// Base font family - Guyot Headline
  static const String _fontFamily = 'GuyotHeadline';

  /// Letter spacing for buttons (from website: 2.2px)
  static const double buttonLetterSpacing = 2.2;

  // ==================
  // HEADING STYLES
  // ==================

  /// H1 - Large headings
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
    color: AppColors.black,
    height: 1.2,
  );

  /// H2 - Section headings
  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
    color: AppColors.black,
    height: 1.3,
  );

  /// H3 - Subsection headings
  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    color: AppColors.black,
    height: 1.4,
  );

  /// H4 - Card titles
  static const TextStyle h4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    color: AppColors.black,
    height: 1.4,
  );

  // ==================
  // BODY STYLES
  // ==================

  /// Body Large - Primary body text
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    color: AppColors.black,
    height: 1.6,
  );

  /// Body Medium - Secondary body text
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    color: AppColors.black,
    height: 1.5,
  );

  /// Body Small - Tertiary body text
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    color: AppColors.textGray,
    height: 1.5,
  );

  // ==================
  // BUTTON STYLES
  // ==================

  /// Button text - with characteristic letter spacing
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    letterSpacing: buttonLetterSpacing,
    color: AppColors.white,
  );

  /// Button text small
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    letterSpacing: buttonLetterSpacing,
    color: AppColors.white,
  );

  // ==================
  // SPECIAL STYLES
  // ==================

  /// Caption - Small annotations
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    color: AppColors.textGray,
    height: 1.4,
  );

  /// Label - Input labels
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontStyle: FontStyle.normal,
    color: AppColors.textGray,
    height: 1.4,
  );

  /// Overline - Small uppercase text
  static const TextStyle overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.normal,
    letterSpacing: 1.5,
    color: AppColors.textGray,
  );

  // ==================
  // GLOBE SPECIFIC
  // ==================

  /// Alumni name on marker popup
  static const TextStyle alumniName = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
    color: AppColors.white,
    height: 1.3,
  );

  /// Location text on marker popup
  static const TextStyle locationText = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontStyle: FontStyle.normal,
    color: AppColors.white,
    height: 1.4,
  );

  /// Cohort badge text
  static const TextStyle cohortBadge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    fontStyle: FontStyle.normal,
    letterSpacing: 1.2,
    color: AppColors.white,
  );
}
