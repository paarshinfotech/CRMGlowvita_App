import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Colors
  static const Color primaryMaroon = Color(0xFF4A2C3C);
  static const Color accentMaroon = Color(0xFFF6F0F2);

  // Backgrounds
  static const Color scaffoldBackground = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color surfaceBackground = Color(0xFFF7F7F8);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryMaroon,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryMaroon,
        secondary: AppColors.primaryMaroon,
        surface: AppColors.surfaceBackground,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      textTheme: GoogleFonts.poppinsTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryMaroon,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primaryMaroon, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.primaryMaroon,
        labelColor: AppColors.primaryMaroon,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
      ),
    );
  }
}
