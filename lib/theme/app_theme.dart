import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF30BCC9);
  static const Color lightTeal = Color(0xFFE1F5F7);
  static const Color background = Color(0xFFF9FDFF);
  static const Color textDark = Color(0xFF2D3142);
  static const Color textLight = Color(0xFF9094A6);
  static const Color white = Colors.white;
  static const Color softPurple = Color(0xFFE6E6FA);
  static const Color lightPink = Color(0xFFFDEEF4);

  static ThemeData get light {
    final textTheme = GoogleFonts.outfitTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: lightTeal,
        surface: white,
        background: background,
      ),
      scaffoldBackgroundColor: background,
      // Enforce a consistent, slightly lighter heading weight and compact sizes
      textTheme: textTheme.copyWith(
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.2,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 12,
          color: textDark,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          color: textLight,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 11,
          color: textLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          shadowColor: primaryTeal.withOpacity(0.5),
          textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F7F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        hintStyle: GoogleFonts.outfit(color: textLight, fontSize: 15),
      ),
    );
  }

  static Gradient get primaryGradient => const LinearGradient(
        colors: [primaryTeal, Color(0xFF5ED3DF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static Gradient get splashGradient => const LinearGradient(
        colors: [white, Color(0xFFF0F9FA), Color(0xFFF8E7F0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
