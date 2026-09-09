import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF001128);
  static const Color primaryContainer = Color(0xFF0A2647);
  static const Color secondary = Color(0xFF994700);
  static const Color secondaryContainer = Color(0xFFFB7800);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF44474E);
  static const Color outline = Color(0xFF74777F);
  static const Color outlineVariant = Color(0xFFC4C6CF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -0.72),
        headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
        labelMedium: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
        labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
