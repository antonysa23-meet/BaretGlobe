import 'package:flutter/material.dart';

/// Baret Scholars brand colors extracted from the official website
/// Reference: baret-scholars-v2.webflow.shared.14c147511.css
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  /// Primary blue color used for CTAs and accents
  /// Hex: #4582d8
  static const Color primaryBlue = Color(0xFF4582D8);

  /// Secondary sage/teal color - signature Baret color
  /// This should be prominent throughout the app
  /// Hex: #4d9c97
  static const Color secondarySage = Color(0xFF4D9C97);

  /// White color for backgrounds and text on dark surfaces
  /// Hex: #ffffff
  static const Color white = Color(0xFFFFFFFF);

  /// Black color for text and contrast elements
  /// Hex: #000000
  static const Color black = Color(0xFF000000);

  /// Soft gray for subtle backgrounds
  /// Hex: #fafafa
  static const Color softGray = Color(0xFFFAFAFA);

  /// Text gray for secondary text
  /// Hex: #758696
  static const Color textGray = Color(0xFF758696);

  /// Error/warning color
  static const Color error = Color(0xFFE53935);

  /// Success color (derived from sage green)
  static const Color success = Color(0xFF4CAF50);

  /// Semi-transparent black for overlays
  static const Color overlay = Color(0x80000000);

  /// Globe colors for 3D visualization
  static const Color globeBackground = Color(0xFF1A1A2E); // Dark space
  static const Color globeStars = Color(0xFFFFFFFF);
  static const Color globeClouds = Color(0xCCFFFFFF); // Semi-transparent white

  /// Marker colors for different cohorts (can be customized)
  static const List<Color> cohortColors = [
    Color(0xFF4582D8), // 2023 - Blue
    Color(0xFF4D9C97), // 2024 - Sage
    Color(0xFFE57373), // 2025 - Coral
    Color(0xFF81C784), // 2026 - Green
    Color(0xFFFFB74D), // 2027 - Orange
    Color(0xFF9575CD), // 2028 - Purple
  ];

  /// Get cohort color by year
  static Color getCohortColor(int cohortYear) {
    const baseYear = 2023;
    final index = (cohortYear - baseYear) % cohortColors.length;
    return cohortColors[index >= 0 ? index : 0];
  }
}
