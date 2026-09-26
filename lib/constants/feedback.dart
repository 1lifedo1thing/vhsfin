import 'dart:async';

import 'package:flutter/services.dart';

/// Short sounds that ride along with presses (see [DeckFeedback]).
enum DeckUiSound {
  /// A short, dry tick — icons, close, menus, checkboxes, list rows.
  tick,

  /// The slot flap's springy tick — choosing a shelf, a TV, a sort order.
  select,

  /// A key going down — the VCR's eject button.
  key,

  /// A switch snapping over — a low, weighty chonk.
  toggle,

  /// A sheet rising: a soft, thumpy whoosh up.
  sheetUp,

  /// A sheet going away: the whoosh back down.
  sheetDown,
}

/// The deck's feel under your finger. Each kind of control has one haptic and
/// one sound, chosen for what the control is physically:
///
/// | control                               | sound   | haptic            |
/// | ------------------------------------- | ------- | ----------------- |
/// | hardware keys (on the way down)       | key     | medium            |
/// | slide switches                        | chonk   | heavy, then light |
/// | shelf / TV / sort choices             | select  | light, then ring  |
/// | icons, close, menus, checkboxes, rows | tick    | light             |
/// | pulling a tape off the shelf          | —       | light             |
/// | sheets opening / closing              | whoosh  | light on the thump |
///
/// Android's `selectionClick` is a "clock tick" many phones skip, so light
/// touches use `lightImpact`, which every device plays.
///
/// Sounds play through [player], which the app attaches (and which respects
/// the SOUND EFFECTS setting); widgets and tests without one stay silent.
///
/// Haptics follow the shape of their sound: a follow-up pulse lands where
/// the sound has a second beat (the flap's ring, the chonk settling, the
/// whoosh's thump). Follow-ups only run with [richHaptics] on (the app turns
/// it on; tests leave it off so they don't leave timers behind).
abstract final class DeckFeedback {
  static void Function(DeckUiSound sound)? player;

  static bool richHaptics = false;

  static void _then(Duration after, void Function() pulse) {
    if (richHaptics) Timer(after, pulse);
  }

  /// Icons, close, menus, list rows, links, back: a dry tick — one light
  /// pulse, no ring.
  static void tap() {
    HapticFeedback.lightImpact();
    player?.call(DeckUiSound.tick);
  }

  /// Checking or unchecking a box: the same dry tick.
  static void check() => tap();

  /// Choosing one of a set — a shelf look, a TV, a sort order. The flap
  /// tick rings, so a faint second pulse follows it.
  static void select() {
    HapticFeedback.lightImpact();
    _then(const Duration(milliseconds: 40), HapticFeedback.selectionClick);
    player?.call(DeckUiSound.select);
  }

  /// Taking a tape off the shelf: felt, not heard (the sheet whooshes).
  static void pick() => HapticFeedback.lightImpact();

  /// A hardware key going down.
  static void key() {
    HapticFeedback.mediumImpact();
    player?.call(DeckUiSound.key);
  }

  /// A switch snapping to its other position: a heavy thump, then the
  /// lighter settle the chonk has in its body.
  static void toggle() {
    HapticFeedback.heavyImpact();
    _then(const Duration(milliseconds: 70), HapticFeedback.lightImpact);
    player?.call(DeckUiSound.toggle);
  }

  /// A small mechanism moving: the slot flap, the eject button. The tape
  /// clips carry their own sound, so this is felt only.
  static void latch() => HapticFeedback.lightImpact();

  /// The cassette seating in, or popping out of, the deck (felt only).
  static void clunk() => HapticFeedback.heavyImpact();

  /// Wraps a sheet or dialog: whoosh up as it opens, down once it's gone —
  /// however it was dismissed. The pulses land on each whoosh's thump (0.24s up, 0.20s down).
  static Future<T?> sheet<T>(Future<T?> Function() open) {
    player?.call(DeckUiSound.sheetUp);
    _then(const Duration(milliseconds: 240), HapticFeedback.lightImpact);
    return open().whenComplete(() {
      player?.call(DeckUiSound.sheetDown);
      _then(const Duration(milliseconds: 200), HapticFeedback.lightImpact);
    });
  }
}
