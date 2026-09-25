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

  /// Painted cassette mouth; title + tape-flight landing target.
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
      slot: Rect.fromLTRB(0.226, 0.770, 0.774, 0.852),
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
    CrtTvSkin.graphite => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(39, 42, 473, 445),
      screen: Rect.fromLTRB(0.089, 0.077, 0.919, 0.725),
      slot: Rect.fromLTRB(0.222, 0.778, 0.753, 0.862),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.284, 0.883, 0.362, 0.930),
          DeckKeyAction.rewind,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.391, 0.883, 0.469, 0.930),
          DeckKeyAction.playPause,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.500, 0.883, 0.578, 0.930),
          DeckKeyAction.fastForward,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.609, 0.883, 0.687, 0.930),
          DeckKeyAction.eject,
        ),
      ],
      remote: Rect.fromLTRB(0.045, 0.78, 0.175, 0.92),
      full: Rect.fromLTRB(0.74, 0.72, 0.96, 0.94),
    ),
    CrtTvSkin.ivory => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(512, 41, 512, 446),
      screen: Rect.fromLTRB(0.119, 0.079, 0.897, 0.732),
      slot: Rect.fromLTRB(0.255, 0.787, 0.727, 0.862),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.300, 0.888, 0.374, 0.940),
          DeckKeyAction.rewind,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.400, 0.888, 0.472, 0.940),
          DeckKeyAction.playPause,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.500, 0.888, 0.573, 0.940),
          DeckKeyAction.fastForward,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.601, 0.888, 0.674, 0.940),
          DeckKeyAction.eject,
        ),
      ],
      remote: Rect.fromLTRB(0.07, 0.80, 0.20, 0.94),
      full: Rect.fromLTRB(0.76, 0.74, 0.97, 0.94),
    ),
    CrtTvSkin.crimson => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(19, 512, 493, 448),
      screen: Rect.fromLTRB(0.087, 0.077, 0.900, 0.684),
      slot: Rect.fromLTRB(0.217, 0.752, 0.749, 0.836),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.260, 0.865, 0.349, 0.921),
          DeckKeyAction.rewind,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.378, 0.865, 0.467, 0.921),
          DeckKeyAction.playPause,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.495, 0.865, 0.584, 0.921),
          DeckKeyAction.fastForward,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.613, 0.865, 0.702, 0.921),
          DeckKeyAction.eject,
        ),
      ],
      remote: Rect.fromLTRB(0.035, 0.76, 0.165, 0.92),
      full: Rect.fromLTRB(0.73, 0.70, 0.97, 0.93),
    ),
    CrtTvSkin.knob => const CrtSpriteLayout(
      asset: 'assets/knob.png',
      assetSize: Size(495, 481),
      sourceRect: Rect.fromLTWH(2, 0, 490, 481),
      screen: Rect.fromLTRB(0.106, 0.108, 0.730, 0.603),
      slot: Rect.fromLTRB(0.188, 0.800, 0.786, 0.878),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.256, 0.899, 0.348, 0.958),
          DeckKeyAction.rewind,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.370, 0.899, 0.459, 0.958),
          DeckKeyAction.play,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.484, 0.899, 0.576, 0.958),
          DeckKeyAction.pause,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.598, 0.899, 0.690, 0.958),
          DeckKeyAction.fastForward,
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
      slot: Rect.fromLTRB(0.200, 0.770, 0.784, 0.852),
      keys: [
        DeckKeycap(
          Rect.fromLTRB(0.256, 0.874, 0.348, 0.928),
          DeckKeyAction.rewind,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.370, 0.874, 0.459, 0.928),
          DeckKeyAction.play,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.481, 0.874, 0.573, 0.928),
          DeckKeyAction.pause,
          printed: true,
        ),
        DeckKeycap(
          Rect.fromLTRB(0.594, 0.874, 0.687, 0.928),
          DeckKeyAction.fastForward,
          printed: true,
        ),
      ],
      remote: Rect.fromLTRB(0.76, 0.14, 0.96, 0.52),
      full: Rect.fromLTRB(0.82, 0.78, 0.96, 0.92),
    ),
  };
}
