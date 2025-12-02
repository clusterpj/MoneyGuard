import 'package:flutter/material.dart';

class AppColors {
  // Primary Backgrounds
  static const Color backgroundPrimary = Color(0xFF0F172A); // slate-900
  static const Color backgroundSecondary = Color(0xFF1E293B); // slate-800
  static const Color backgroundTertiary = Color(0xFF334155); // slate-700

  // Accent Gradient
  static const Color accentStart = Color(0xFF6366F1); // indigo-500
  static const Color accentEnd = Color(0xFFA855F7); // purple-500

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // white
  static const Color textSecondary = Color(0xFF94A3B8); // slate-400
  static const Color textMuted = Color(0xFF64748B); // slate-500

  // Semantic Colors
  static const Color success = Color(0xFF34D399); // green-400
  static const Color warning = Color(0xFFFBBF24); // yellow-400
  static const Color error = Color(0xFFF87171); // red-400

  // Category Colors
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
    color: accentStart.withOpacity(0.15),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  static BoxShadow buttonGlow = BoxShadow(
    color: accentStart.withOpacity(0.3),
    blurRadius: 16,
    offset: const Offset(0, 4),
  );

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [accentStart, accentEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
