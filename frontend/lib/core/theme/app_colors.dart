import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Clean Wealth)
  static const Color brandPrimary = Color(0xFF3A5F56); // Deep desaturated green
  static const Color brandSecondary = Color(0xFF6BA28E); // Muted mint green
  static const Color brandAccent = Color(0xFFF4C95D); // Soft gold

  // Background Surfaces
  static const Color backgroundPrimary = Color(0xFFF0F5F3); // Soft off-white
  static const Color backgroundSecondary = Color(
    0xFFFFFFFF,
  ); // White (Cards/Surfaces)
  static const Color backgroundTertiary = Color(0xFFC9D7D2); // Cool grey-green

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937); // Charcoal Dark
  static const Color textSecondary = Color(0xFF4B5563); // Charcoal Medium
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400 (unchanged-ish)

  // Semantic Colors
  static const Color success = Color(0xFF34D399); // Green 400
  static const Color warning = Color(0xFFFBBF24); // Yellow 400
  static const Color error = Color(0xFFF87171); // Red 400

  // --- COMPATIBILITY ALIASES (Mapping old theme to new Clean Wealth) ---
  // These allow the rest of the app to compile while switching to the new palette.
  static const Color accentStart = brandPrimary;
  static const Color accentEnd = brandSecondary;
  static const Color primary = brandPrimary;
  static const Color shadow = Color(
    0xFF000000,
  ); // Keep generic black for shadows where needed

  // Category Colors (Legacy/Existing Support)
  static const Map<String, Color> categoryColors = {
    'food': Color(0xFFFF6B6B),
    'transport': Color(0xFF4ECDC4),
    'shopping': Color(0xFFA78BFA),
    'entertainment': Color(0xFFFBBF24),
    'bills': Color(0xFF60A5FA),
    'health': Color(0xFF34D399),
    'other': Color(0xFF94A3B8),
  };

  // Shadows
  static BoxShadow cardShadow = BoxShadow(
    color: brandPrimary.withValues(alpha: 0.08),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  static BoxShadow buttonGlow = BoxShadow(
    color: brandPrimary.withValues(alpha: 0.3),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brandPrimary, brandSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
