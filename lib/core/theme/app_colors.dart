import 'package:flutter/material.dart';

/// Application color palette for light and dark themes.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF00695C);
  static const Color primaryLight = Color(0xFF26A69A);
  static const Color primaryDark = Color(0xFF004D40);
  static const Color secondary = Color(0xFF00897B);
  static const Color accent = Color(0xFFFFB74D);

  // Semantic
  static const Color income = Color(0xFF2E7D32);
  static const Color expense = Color(0xFFC62828);
  static const Color transfer = Color(0xFF1565C0);
  static const Color savings = Color(0xFF6A1B9A);
  static const Color warning = Color(0xFFF57C00);
  static const Color success = Color(0xFF388E3C);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // Neutral - Light
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color dividerLight = Color(0xFFE5E7EB);

  // Neutral - Dark
  static const Color backgroundDark = Color(0xFF0F1419);
  static const Color surfaceDark = Color(0xFF1A2332);
  static const Color cardDark = Color(0xFF243044);
  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color dividerDark = Color(0xFF374151);

  // Chart colors
  static const List<Color> chartPalette = [
    Color(0xFF00695C),
    Color(0xFF26A69A),
    Color(0xFFFFB74D),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFF66BB6A),
    Color(0xFFFF7043),
    Color(0xFF78909C),
    Color(0xFFEC407A),
  ];
}
