import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color forestGreen = Color(0xFF213C2B);
  static const Color terracotta = Color(0xFFDC7759);

  // Light Palette
  static const Color lightBg = Color(0xFFF3F6F1);
  static const Color lightSurface = Color(0xFFEDF2EB);
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1A2920);
  static const Color lightTextSecondary = Color(0xFF5D6E64);
  static const Color lightBorder = Color(0xFFD5DFD3);

  // Dark Palette
  static const Color darkBg = Color(0xFF121A15);
  static const Color darkSurface = Color(0xFF1B2720);
  static const Color darkCard = Color(0xFF1C2821);
  static const Color darkTextPrimary = Color(0xFFEAF0EC);
  static const Color darkTextSecondary = Color(0xFF9FB0A5);
  static const Color darkBorder = Color(0xFF2B3A31);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      primaryColor: AppColors.forestGreen,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forestGreen,
        secondary: AppColors.terracotta,
        surface: AppColors.lightCard,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.forestGreen,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.forestGreen,
        secondary: AppColors.terracotta,
        surface: AppColors.darkCard,
      ),
      useMaterial3: true,
    );
  }
}