import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Baret Scholars app theme matching the official website aesthetic
class AppTheme {
  AppTheme._(); // Private constructor

  /// Light theme (primary theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.secondarySage, // Sage green as primary
        secondary: AppColors.accentGold, // Gold for accents/highlights
        tertiary: AppColors.primaryBlue, // Blue for secondary CTAs
        surface: AppColors.white,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.black, // Dark text on gold
        onTertiary: AppColors.white, // White text on blue
        onSurface: AppColors.black,
        onError: AppColors.white,
      ),

      // Scaffold background
      scaffoldBackgroundColor: AppColors.white,

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.h3,
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1.copyWith(fontStyle: FontStyle.normal),
        displayMedium: AppTextStyles.h2.copyWith(fontStyle: FontStyle.normal),
        displaySmall: AppTextStyles.h3.copyWith(fontStyle: FontStyle.normal),
        headlineMedium: AppTextStyles.h4.copyWith(fontStyle: FontStyle.normal),
        headlineSmall: AppTextStyles.h4.copyWith(fontStyle: FontStyle.normal),
        titleLarge: AppTextStyles.h4.copyWith(fontStyle: FontStyle.normal),
        titleMedium:
            AppTextStyles.bodyLarge.copyWith(fontStyle: FontStyle.normal),
        titleSmall:
            AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.normal),
        bodyLarge:
            AppTextStyles.bodyLarge.copyWith(fontStyle: FontStyle.normal),
        bodyMedium:
            AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.normal),
        bodySmall:
            AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.normal),
        labelLarge: AppTextStyles.button.copyWith(fontStyle: FontStyle.normal),
        labelMedium:
            AppTextStyles.buttonSmall.copyWith(fontStyle: FontStyle.normal),
        labelSmall: AppTextStyles.caption.copyWith(fontStyle: FontStyle.normal),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondarySage,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(50), // Pill-shaped (from website)
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondarySage,
          side: const BorderSide(color: AppColors.secondarySage, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondarySage,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.button,
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondarySage,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutralGray100, // Updated neutral
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 18), // Increased
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Reduced from 25
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: AppColors.accentGold, width: 2), // Gold focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.label,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textGray,
          fontStyle: FontStyle.normal,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 1, // Reduced from 2 for softer shadows
        shadowColor: AppColors.black.withOpacity(0.05), // Softer shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Increased from 16
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.accentGold, // Changed to gold
        unselectedItemColor: AppColors.neutralGray400, // Updated gray
        selectedLabelStyle: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontStyle: FontStyle.normal,
        ),
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 4, // Reduced from 8
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Increased from 20
        ),
        titleTextStyle: AppTextStyles.h3,
        contentTextStyle: AppTextStyles.bodyMedium,
        actionsPadding: const EdgeInsets.all(24),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.black,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.white,
          fontStyle: FontStyle.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.softGray,
        selectedColor: AppColors.secondarySage,
        labelStyle: AppTextStyles.bodySmall,
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: AppColors.white,
          fontStyle: FontStyle.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentGold, // Changed to gold
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: AppColors.textGray.withOpacity(0.2),
        thickness: 1,
        space: 16,
      ),
    );
  }

  /// Dark theme for globe view (space aesthetic)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.secondarySage,
        secondary: AppColors.primaryBlue,
        surface: AppColors.globeBackground,
        error: AppColors.error,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.white,
        onError: AppColors.white,
      ),

      scaffoldBackgroundColor: AppColors.globeBackground,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.globeBackground,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.h3.copyWith(
          color: AppColors.white,
          fontStyle: FontStyle.normal,
        ),
      ),

      // Buttons remain the same for consistency
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondarySage,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondarySage,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }
}
