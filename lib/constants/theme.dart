import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Living-room palette: a dark room, charcoal plastics, and a VCR's cyan
/// fluorescent display. Red is reserved for record/insert actions.
abstract final class VhsColors {
  /// Page ground and the deepest shadows.
  static const room = Color(0xFF07090B);

  /// Faint cool glow behind the TV.
  static const roomGlow = Color(0xFF14191D);

  /// Sheets, dialogs, and panels.
  static const surface = Color(0xFF111417);

  /// Cards and rows sitting on a [surface].
  static const surfaceRaised = Color(0xFF191D21);

  /// Recessed wells (shelf cavities, inputs).
  static const surfaceSunken = Color(0xFF0B0D0F);

  /// Hairlines and card borders.
  static const line = Color(0xFF272D33);

  /// Primary text.
  static const ink = Color(0xFFE6ECEE);

  /// Secondary text and icons.
  static const inkMuted = Color(0xFF98A4AB);

  /// Captions and disabled text.
  static const inkFaint = Color(0xFF5C676E);

  /// VFD cyan — selection, labels, progress, focus.
  static const accent = Color(0xFF6FE0E6);

  /// Accent at rest (switch tracks, dim borders).
  static const accentDim = Color(0xFF1E4648);

  /// Selected rows and cards: [surfaceRaised] washed with [accent].
  static const accentWash = Color(0xFF14292C);

  /// Record red — INSERT and the REC dot.
  static const record = Color(0xFFE0483E);

  /// Error banners: [surface] washed with [record].
  static const recordWash = Color(0xFF331719);

  static const vcrBody = Color(0xFF1C1C1E);
  static const vcrFace = Color(0xFF2A2A2E);
  static const vcrBezel = Color(0xFF0C0C0E);
  static const tapeShell = Color(0xFFD4C4A0);
  static const tapeLabel = Color(0xFFF7F0E0);
  static const ledOff = Color(0xFF3A1515);
  static const ledOn = Color(0xFFFF4A3A);
}

ThemeData buildVhsTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: VhsColors.room,
    colorScheme: const ColorScheme.dark(
      primary: VhsColors.accent,
      secondary: VhsColors.record,
      surface: VhsColors.surface,
      onPrimary: VhsColors.room,
      onSecondary: VhsColors.ink,
      onSurface: VhsColors.ink,
      onSurfaceVariant: VhsColors.inkMuted,
      outline: VhsColors.line,
    ),
  );

  return base.copyWith(
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme)
        .apply(bodyColor: VhsColors.ink, displayColor: VhsColors.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.bungee(fontSize: 22, color: VhsColors.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VhsColors.surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      labelStyle: const TextStyle(color: VhsColors.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: VhsColors.record,
        foregroundColor: VhsColors.ink,
        textStyle: GoogleFonts.bungee(fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );
}

TextStyle vhsBrandStyle({double size = 48}) {
  return GoogleFonts.bungee(
    fontSize: size,
    color: VhsColors.ink,
    letterSpacing: 2,
    height: 1.05,
  );
}

/// Shared generated artwork for welcome and launch surfaces.
class VhsBrandIcon extends StatelessWidget {
  const VhsBrandIcon({super.key, this.size = 96});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'VHSFin',
    image: true,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/icons/app_icon_1024.png',
        excludeFromSemantics: true,
      ),
    ),
  );
}

/// Closes the enclosing route on Escape. Bottom sheets don't do this on their
/// own when focus hasn't moved into them (web/desktop).
class DismissOnEscape extends StatelessWidget {
  const DismissOnEscape({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.of(context).maybePop(),
    },
    child: Focus(autofocus: true, child: child),
  );
}
