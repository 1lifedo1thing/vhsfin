import 'package:flutter/material.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';

/// What pressing a transport key on the cabinet does.
enum DeckKeyAction {
  rewind('REW'),
  play('PLAY'),

  /// Pauses — a VCR's STOP keeps the tape where it is.
  pause('PAUSE'),

  /// One key that plays or pauses, for decks with only four keys.
  playPause('PLAY'),
  fastForward('FF'),
  eject('EJECT');

  const DeckKeyAction(this.label);
  final String label;
}

/// One keycap painted on the cabinet art.
class DeckKeycap {
  const DeckKeycap(this.rect, this.action, {this.printed = false});

  /// The cap's face as fractions of [CrtSpriteLayout.sourceRect].
  final Rect rect;
  final DeckKeyAction action;

  /// The art already prints this key's symbol, so none is drawn over it.
  final bool printed;
}

/// Source crop and normalized hit areas for one CRT cabinet asset.
class CrtSpriteLayout {
  const CrtSpriteLayout({
    required this.asset,
    required this.assetSize,
    required this.sourceRect,
    required this.screen,
    required this.slot,
    required this.keys,
    required this.remote,
    required this.full,
  });

  final String asset;
  final Size assetSize;

  /// Crop within [asset]. Height ends at the feet so the cabinet plants on the
  /// shelf ledge.
  final Rect sourceRect;

  /// Video aperture as fractions of [sourceRect]. Centered on the transparent
  /// glass hole, expanded a hair under the opaque bezel.
  final Rect screen;

  /// The dark recess of the painted cassette mouth (measured on the art);
  /// title plate and tape-flight landing target.
  final Rect slot;

  /// Transport keycaps under the mouth, left to right, measured on the art.
  final List<DeckKeycap> keys;

  /// Power button or tuning knobs — opens the remote.
  final Rect remote;

  /// Speaker grille / side panel — fullscreen.
  final Rect full;

  /// How far feet may overlap the shelf ledge, as a fraction of cabinet width.
  static const shelfPlant = 0.014;

  static const _atlas = 'assets/crts.png';
  static const _atlasSize = Size(1536, 1024);

  static CrtSpriteLayout of(CrtTvSkin skin) => switch (skin) {
    CrtTvSkin.crt90s => const CrtSpriteLayout(
      asset: 'assets/branding/crt-90s.png',
      assetSize: Size(1254, 1254),
      // Feet land at ~97.3% of the square canvas.
      sourceRect: Rect.fromLTWH(0, 0, 1254, 1220),
      screen: Rect.fromLTRB(0.089, 0.099, 0.911, 0.718),
      slot: Rect.fromLTRB(0.224, 0.782, 0.777, 0.856),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.275, 0.889, 0.350, 0.928),
          DeckKeyAction.rewind,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.369, 0.889, 0.443, 0.928),
          DeckKeyAction.play,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.463, 0.889, 0.538, 0.928),
          DeckKeyAction.pause,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.557, 0.889, 0.632, 0.928),
          DeckKeyAction.fastForward,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.652, 0.889, 0.726, 0.928),
          DeckKeyAction.eject,
        ),
      ],
      remote: Rect.fromLTRB(0.05, 0.785, 0.14, 0.875),
      full: Rect.fromLTRB(0.78, 0.70, 0.95, 0.90),
    ),
    CrtTvSkin.crtIcon => const CrtSpriteLayout(
      asset: 'assets/branding/crt-icon-cutout-v3.png',
      assetSize: Size(1254, 1254),
      sourceRect: Rect.fromLTWH(0, 0, 1254, 1212),
      screen: Rect.fromLTRB(0.125, 0.136, 0.876, 0.719),
      slot: Rect.fromLTRB(0.206, 0.776, 0.666, 0.865),
      // Keycaps are painted on the strip below the cassette mouth.
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.226, 0.880, 0.316, 0.929),
          DeckKeyAction.rewind,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.333, 0.880, 0.428, 0.929),
          DeckKeyAction.playPause,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.446, 0.880, 0.538, 0.929),
          DeckKeyAction.fastForward,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.555, 0.880, 0.645, 0.929),
          DeckKeyAction.eject,
          printed: true,
        ),
      ],
      remote: Rect.fromLTRB(0.788, 0.746, 0.911, 0.883),
      full: Rect.fromLTRB(0.705, 0.773, 0.801, 0.873),
    ),
    CrtTvSkin.graphite => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(39, 42, 477, 446),
      screen: Rect.fromLTRB(0.088, 0.077, 0.911, 0.723),
      slot: Rect.fromLTRB(0.220, 0.776, 0.747, 0.860),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.282, 0.881, 0.359, 0.928),
          DeckKeyAction.rewind,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.388, 0.881, 0.465, 0.928),
          DeckKeyAction.playPause,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.496, 0.881, 0.573, 0.928),
          DeckKeyAction.fastForward,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.604, 0.881, 0.681, 0.928),
          DeckKeyAction.eject,
        ),
      ],
      remote: Rect.fromLTRB(0.045, 0.778, 0.174, 0.918),
      full: Rect.fromLTRB(0.734, 0.718, 0.952, 0.938),
    ),
    CrtTvSkin.ivory => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(537, 41, 469, 447),
      screen: Rect.fromLTRB(0.077, 0.079, 0.926, 0.730),
      slot: Rect.fromLTRB(0.222, 0.783, 0.742, 0.861),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.274, 0.886, 0.355, 0.938),
          DeckKeyAction.rewind,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.383, 0.886, 0.462, 0.938),
          DeckKeyAction.playPause,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.493, 0.886, 0.572, 0.938),
          DeckKeyAction.fastForward,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.603, 0.886, 0.682, 0.938),
          DeckKeyAction.eject,
        ),
      ],
      remote: Rect.fromLTRB(0.023, 0.798, 0.165, 0.938),
      full: Rect.fromLTRB(0.776, 0.738, 1.000, 0.938),
    ),
    CrtTvSkin.crimson => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(19, 510, 505, 451),
      screen: Rect.fromLTRB(0.085, 0.081, 0.879, 0.684),
      slot: Rect.fromLTRB(0.202, 0.749, 0.733, 0.838),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.254, 0.864, 0.341, 0.919),
          DeckKeyAction.rewind,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.369, 0.864, 0.456, 0.919),
          DeckKeyAction.playPause,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.483, 0.864, 0.570, 0.919),
          DeckKeyAction.fastForward,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.598, 0.864, 0.685, 0.919),
          DeckKeyAction.eject,
        ),
      ],
      remote: Rect.fromLTRB(0.034, 0.759, 0.161, 0.918),
      full: Rect.fromLTRB(0.713, 0.700, 0.947, 0.928),
    ),
    CrtTvSkin.knob => const CrtSpriteLayout(
      asset: 'assets/knob.png',
      assetSize: Size(495, 481),
      sourceRect: Rect.fromLTWH(2, 0, 490, 481),
      screen: Rect.fromLTRB(0.106, 0.108, 0.730, 0.603),
      slot: Rect.fromLTRB(0.186, 0.796, 0.788, 0.879),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.256, 0.899, 0.348, 0.958),
          DeckKeyAction.rewind,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.370, 0.899, 0.459, 0.958),
          DeckKeyAction.playPause,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.484, 0.899, 0.576, 0.958),
          DeckKeyAction.fastForward,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.598, 0.899, 0.690, 0.958),
          DeckKeyAction.eject,
          printed: true,
        ),
      ],
      remote: Rect.fromLTRB(0.76, 0.14, 0.96, 0.52),
      full: Rect.fromLTRB(0.82, 0.78, 0.96, 0.92),
    ),
    CrtTvSkin.knob2 => const CrtSpriteLayout(
      asset: 'assets/knob2.png',
      assetSize: Size(498, 477),
      sourceRect: Rect.fromLTWH(3, 2, 493, 475),
      screen: Rect.fromLTRB(0.106, 0.108, 0.728, 0.602),
      slot: Rect.fromLTRB(0.195, 0.773, 0.759, 0.857),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.256, 0.874, 0.348, 0.928),
          DeckKeyAction.rewind,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.370, 0.874, 0.459, 0.928),
          DeckKeyAction.playPause,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.481, 0.874, 0.573, 0.928),
          DeckKeyAction.fastForward,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.594, 0.874, 0.687, 0.928),
          DeckKeyAction.eject,
          printed: true,
        ),
      ],
      remote: Rect.fromLTRB(0.76, 0.14, 0.96, 0.52),
      full: Rect.fromLTRB(0.82, 0.78, 0.96, 0.92),
    ),
  };
}
