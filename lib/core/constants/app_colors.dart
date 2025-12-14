import 'package:flutter/material.dart';

/// Centralized color palette that reflects the Gulf-inspired branding.
class AppColors {
  static const Color primary = Color(0xFF007C91);
  static const Color primaryDark = Color(0xFF004E5B);
  static const Color secondary = Color(0xFFFFC857);
  static const Color accent = Color(0xFF34C38F);
  static const Color surface = Color(0xFFF4F7F9);
  static const Color background = Color(0xFFFBFCFE);
  static const Color textPrimary = Color(0xFF0D1C2E);
  static const Color textSecondary = Color(0xFF5A6A78);
  static const Color danger = Color(0xFFE74C3C);
  static const Color info = Color(0xFF4C6EF5);
  static const Color success = Color(0xFF2DBE78);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0C6170), Color(0xFF0A3941)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
