import 'package:flutter/material.dart';
import 'package:moneyguard/core/theme/app_colors.dart';
import 'package:moneyguard/core/theme/app_typography.dart';

class AppTheme {
  // Clean Wealth Theme (Light Mode)
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundPrimary, // Soft Off-White
    primaryColor: AppColors.brandPrimary, // Deep Green
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.brandPrimary,
      secondary: AppColors.brandSecondary,
      tertiary: AppColors.brandAccent,
      surface: AppColors.backgroundSecondary, // White used for cards usually
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
    ),

    // Typography
    textTheme:
        const TextTheme(
          displayLarge: AppTypography.displayLarge,
          headlineMedium: AppTypography.headlineMedium,
          titleLarge: AppTypography.titleLarge,
          titleMedium: AppTypography.titleMedium,
          bodyLarge: AppTypography.bodyLarge,
          bodyMedium: AppTypography.bodyMedium,
          bodySmall: AppTypography.bodySmall,
          labelLarge: AppTypography.labelLarge,
          labelSmall: AppTypography.labelSmall,
        ).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),

    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle:
          AppTypography.titleLarge, // Will inherit textPrimary color
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      surfaceTintColor: Colors.transparent, // Avoid tint on scroll
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: AppColors.backgroundSecondary, // White
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      shadowColor: AppColors.brandPrimary.withValues(alpha: 0.05),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundSecondary, // White
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
      labelStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: AppTypography.labelLarge,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.brandAccent, // Soft Gold
      foregroundColor: AppColors.brandPrimary, // Deep Green text/icon on Gold
      elevation: 4,
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
  );

  // We assign the same theme to 'darkTheme' for now to ensure changing system setting
  // doesn't revert to the old dark UI, effectively forcing the 'Clean Wealth' look.
  static final ThemeData darkTheme = lightTheme;
}
