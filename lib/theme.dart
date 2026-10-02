import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF000624);
  static const card = Color(0xFF0B1238);
  static const key = Color(0xFF1A2358);
  static const accent = Color(0xFF8ECAE6);
  static const gold = Color(0xFFFFD54F);
  static const rainbow = [
    Color(0xFFFF4D00),
    Color(0xFFF9A800),
    Color(0xFFF5FF00),
    Color(0xFF16B8FF),
    Color(0xFF6A4C9C),
  ];
}

const rainbowGradient = LinearGradient(colors: AppColors.rainbow);

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.card,
      ),
    );

double c01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);
