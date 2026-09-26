import 'package:flutter/services.dart';

/// The deck's feel under your finger. One place decides how each kind of
/// interaction lands, so presses stay consistent across the app.
///
/// On web these map to `navigator.vibrate` where the browser supports it.
abstract final class DeckHaptics {
  /// Choosing something: a shelf, a TV, a tape, a row, closing a sheet.
  static void tap() => HapticFeedback.selectionClick();

  /// A hardware key going down.
  static void key() => HapticFeedback.lightImpact();

  /// A switch snapping to its other position.
  static void toggle() => HapticFeedback.mediumImpact();

  /// A small mechanism moving: the slot flap, the eject button.
  static void latch() => HapticFeedback.lightImpact();

  /// The cassette seating in, or popping out of, the deck.
  static void clunk() => HapticFeedback.heavyImpact();
}
