import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Living-room CRT palette: wood, charcoal VCR plastic, phosphor glow.
abstract final class VhsColors {
  static const woodDeep = Color(0xFF1A100C);
  static const woodMid = Color(0xFF2C1A12);
  static const carpet = Color(0xFF1E2E28);
  static const vcrBody = Color(0xFF1C1C1E);
  static const vcrFace = Color(0xFF2A2A2E);
  static const vcrBezel = Color(0xFF0C0C0E);
  static const phosphor = Color(0xFF8FE8A8);
  static const phosphorDim = Color(0xFF3A6B4A);
  static const brand = Color(0xFFF2E6D0);
  static const tapeShell = Color(0xFFD4C4A0);
  static const tapeLabel = Color(0xFFF7F0E0);
  static const accent = Color(0xFFD94A3A);
  static const ledOff = Color(0xFF3A1515);
  static const ledOn = Color(0xFFFF4A3A);
}

ThemeData buildVhsTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: VhsColors.woodDeep,
    colorScheme: const ColorScheme.dark(
      primary: VhsColors.phosphor,
      secondary: VhsColors.accent,
      surface: VhsColors.vcrBody,
      onPrimary: VhsColors.woodDeep,
      onSecondary: VhsColors.brand,
      onSurface: VhsColors.brand,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
      bodyColor: VhsColors.brand,
      displayColor: VhsColors.brand,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.bungee(
        fontSize: 22,
        color: VhsColors.brand,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VhsColors.vcrFace,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: VhsColors.brand),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VhsColors.accent,
        foregroundColor: VhsColors.brand,
        textStyle: GoogleFonts.bungee(fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

TextStyle vhsBrandStyle({double size = 48}) {
  return GoogleFonts.bungee(
    fontSize: size,
    color: VhsColors.brand,
    letterSpacing: 2,
    height: 1.05,
  );
}
