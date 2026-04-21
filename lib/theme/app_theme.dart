import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryTeal = Color(0xFF1F7DAD); // Brand Primary Blue/Teal
  static const Color iconColor = primaryTeal; // Updated to use primary teal
  static const Color lightBackgroundTint = Color(0xFFE0F7F7); // Brand Light Background Tint
  static const Color background = Color(0xFFF8FAFC); // Retained off-white background
  static const Color textDark = Color(0xFF2D2D2D); // Soft readable dark grey
  static const Color textLight = Color(0xFF718096); // Adjusted standard grey for subtext
  static const Color white = Colors.white;
  static const Color softPurple = Color(0xFFE6E6FA);
  static const Color lightPink = Color(0xFFFDEEF4);
  static const Color zenStart = Color(0xFFE0F7FA);
  static const Color zenEnd = Color(0xFFB2EBF2);
  static const Color shadowTeal = Color(0x1A30BCC9); // Very light teal for shadows

  // Premium Glassmorphism Constants
  static const double glassBlur = 25.0;
  static const double glassOpacity = 0.15;

  static List<BoxShadow> get premiumShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: primaryTeal.withOpacity(0.1),
          blurRadius: 40,
          offset: const Offset(0, 20),
        ),
      ];

  static ThemeData get light {
    final textTheme = GoogleFonts.outfitTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: lightBackgroundTint,
        surface: white,
        background: background,
      ),
      scaffoldBackgroundColor: background,
      // Enforce a consistent, slightly lighter heading weight and compact sizes
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600, // Semi-Bold
          color: textDark,
          letterSpacing: -0.5,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.5,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.5,
        ),
        headlineLarge: textTheme.headlineLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.5,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.5,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textDark,
          letterSpacing: -0.5,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500, // Medium
          color: textDark,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400, // Regular
          color: textLight,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal, // Updated to brand teal
          foregroundColor: white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // 20px as requested
          ),
          elevation: 0,
          shadowColor: primaryTeal.withOpacity(0.2),
          textStyle: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.6), // Glassy feel
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20), // 20px as requested
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        hintStyle: GoogleFonts.outfit(color: textDark.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w400),
      ),
    );
  }

  static Gradient get primaryGradient => const LinearGradient(
        colors: [primaryTeal, Color(0xFF009688)], // Adjusted gradient with brand teal variant
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static Gradient get zenGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [zenStart, zenEnd, Colors.white],
      );

  static Gradient get splashGradient => const LinearGradient(
        colors: [white, Color(0xFFF0F9FA), Color(0xFFF8E7F0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
}
