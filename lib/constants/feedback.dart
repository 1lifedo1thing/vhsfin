import 'package:flutter/services.dart';

/// Short sounds that ride along with presses (see [DeckFeedback]).
enum DeckUiSound {
  /// A light plastic tick — the VCR's slot flap.
  tick,

  /// A key going down — the VCR's eject button.
  key,

  /// A switch snapping over — a low, weighty chonk.
  toggle,
}

/// The deck's feel under your finger: one place decides the haptic and the
/// sound for each kind of interaction, so presses stay consistent.
///
/// Haptics map to `navigator.vibrate` on web where supported. Sounds play
/// through [player], which the app attaches (and which respects the SOUND
/// EFFECTS setting); widgets and tests without one stay silent.
abstract final class DeckFeedback {
  static void Function(DeckUiSound sound)? player;

  /// Choosing something: a shelf, a TV, a tape, a row, closing a sheet.
  static void tap() {
    HapticFeedback.selectionClick();
    player?.call(DeckUiSound.tick);
  }

  /// A hardware key going down.
  static void key() {
    HapticFeedback.lightImpact();
    player?.call(DeckUiSound.key);
  }

  /// A switch snapping to its other position.
  static void toggle() {
    HapticFeedback.mediumImpact();
    player?.call(DeckUiSound.toggle);
  }

  /// A small mechanism moving: the slot flap, the eject button. The tape
  /// clips carry their own sound, so this is felt only.
  static void latch() => HapticFeedback.lightImpact();

  /// The cassette seating in, or popping out of, the deck (felt only).
  static void clunk() => HapticFeedback.heavyImpact();
}
