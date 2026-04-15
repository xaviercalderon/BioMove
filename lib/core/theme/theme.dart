import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class BM {
  static const primary    = Color(0xFF6C63FF);
  static const primaryDk  = Color(0xFF4A42CC);
  static const primaryLt  = Color(0xFF9C95FF);
  static const accent     = Color(0xFF00D4AA);
  static const accentDk   = Color(0xFF00A882);
  static const success    = Color(0xFF00D4AA);
  static const warning    = Color(0xFFFFB74D);
  static const error      = Color(0xFFFF5252);
  static const info       = Color(0xFF64B5F6);
  static const moderate   = Color(0xFFFF7043);
  static const bg         = Color(0xFF07070F);
  static const surface    = Color(0xFF0F0F1A);
  static const card       = Color(0xFF161624);
  static const elevated   = Color(0xFF1E1E30);
  static const highlight  = Color(0xFF26263E);
  static const textPrimary   = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFF8080A0);
  static const textHint      = Color(0xFF40405A);

  static const grad1 = LinearGradient(
      colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradHero = LinearGradient(
      colors: [Color(0xFF2D1B8A), Color(0xFF0A5040)],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradCard = LinearGradient(
      colors: [Color(0xFF161624), Color(0xFF0F0F1A)],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradDanger = LinearGradient(
      colors: [Color(0xFFD32F2F), Color(0xFFFF7043)],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradCoach = LinearGradient(
      colors: [Color(0xFF0A5040), Color(0xFF1B4A2D)],
      begin: Alignment.topLeft, end: Alignment.bottomRight);
  static const gradAdmin = LinearGradient(
      colors: [Color(0xFF4A2D00), Color(0xFF1A1000)],
      begin: Alignment.topLeft, end: Alignment.bottomRight);

  static Color scoreColor(double s) {
    if (s >= 90) return const Color(0xFF00D4AA);
    if (s >= 75) return const Color(0xFF69F0AE);
    if (s >= 60) return const Color(0xFFFFB74D);
    return const Color(0xFFFF5252);
  }

  static String scoreLabel(double s) {
    if (s >= 90) return 'Excelente';
    if (s >= 75) return 'Buena técnica';
    if (s >= 60) return 'Aceptable';
    return 'Necesita mejoras';
  }

  static Color severityColor(String s) {
    switch (s) {
      case 'severe':
      case 'riesgo':
        return error;
      case 'moderate':
        return moderate;
      default:
        return warning;
    }
  }

  static Color clfColor(String cls) {
    switch (cls) {
      case 'excelente': return const Color(0xFF00D4AA);
      case 'buena':     return const Color(0xFF69F0AE);
      case 'aceptable': return const Color(0xFFFFB74D);
      case 'mejoras':   return const Color(0xFFFF7043);
      case 'riesgo':    return const Color(0xFFFF5252);
      default:          return textSecondary;
    }
  }
}

class BioMoveTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: BM.primary, secondary: BM.accent,
        surface: BM.surface, error: BM.error,
        onPrimary: Colors.white, onSurface: BM.textPrimary,
      ),
      scaffoldBackgroundColor: BM.bg,
      cardColor: BM.card,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge:   GoogleFonts.poppins(fontSize: 34, fontWeight: FontWeight.w800, color: BM.textPrimary),
        headlineLarge:  GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: BM.textPrimary),
        headlineMedium: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: BM.textPrimary),
        titleLarge:     GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: BM.textPrimary),
        titleMedium:    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: BM.textPrimary),
        bodyLarge:      GoogleFonts.poppins(fontSize: 15, color: BM.textPrimary),
        bodyMedium:     GoogleFonts.poppins(fontSize: 13, color: BM.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BM.bg, elevation: 0, scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(color: BM.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: BM.textPrimary),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BM.primary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: BM.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF202038))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF202038))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: BM.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: BM.error)),
        labelStyle: GoogleFonts.poppins(color: BM.textSecondary, fontSize: 14),
        hintStyle: GoogleFonts.poppins(color: BM.textHint, fontSize: 14),
        prefixIconColor: BM.textHint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? BM.primary : BM.textHint),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? BM.primary.withOpacity(0.3) : BM.elevated),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BM.card,
        contentTextStyle: GoogleFonts.poppins(color: BM.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: BM.surface, selectedItemColor: BM.primary,
        unselectedItemColor: BM.textHint, type: BottomNavigationBarType.fixed, elevation: 0,
      ),
    );
  }
}
