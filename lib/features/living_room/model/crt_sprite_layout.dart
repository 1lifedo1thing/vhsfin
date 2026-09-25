import 'package:flutter/material.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';

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

  /// Transport keycaps under the mouth.
  final Rect keys;

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
      slot: Rect.fromLTRB(0.230, 0.765, 0.770, 0.835),
      keys: Rect.fromLTRB(0.263, 0.850, 0.737, 0.945),
      remote: Rect.fromLTRB(0.05, 0.785, 0.14, 0.875),
      full: Rect.fromLTRB(0.78, 0.70, 0.95, 0.90),
    ),
    CrtTvSkin.graphite => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(39, 42, 473, 445),
      screen: Rect.fromLTRB(0.089, 0.077, 0.919, 0.725),
      slot: Rect.fromLTRB(0.220, 0.785, 0.755, 0.850),
      keys: Rect.fromLTRB(0.280, 0.875, 0.700, 0.940),
      remote: Rect.fromLTRB(0.045, 0.78, 0.175, 0.92),
      full: Rect.fromLTRB(0.74, 0.72, 0.96, 0.94),
    ),
    CrtTvSkin.ivory => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(512, 41, 512, 446),
      screen: Rect.fromLTRB(0.119, 0.079, 0.897, 0.732),
      slot: Rect.fromLTRB(0.295, 0.790, 0.715, 0.855),
      keys: Rect.fromLTRB(0.300, 0.885, 0.700, 0.945),
      remote: Rect.fromLTRB(0.07, 0.80, 0.20, 0.94),
      full: Rect.fromLTRB(0.76, 0.74, 0.97, 0.94),
    ),
    CrtTvSkin.crimson => const CrtSpriteLayout(
      asset: _atlas,
      assetSize: _atlasSize,
      sourceRect: Rect.fromLTWH(19, 512, 493, 448),
      screen: Rect.fromLTRB(0.087, 0.077, 0.900, 0.684),
      slot: Rect.fromLTRB(0.210, 0.760, 0.735, 0.820),
      keys: Rect.fromLTRB(0.255, 0.855, 0.720, 0.920),
      remote: Rect.fromLTRB(0.035, 0.76, 0.165, 0.92),
      full: Rect.fromLTRB(0.73, 0.70, 0.97, 0.93),
    ),
    CrtTvSkin.knob => const CrtSpriteLayout(
      asset: 'assets/knob.png',
      assetSize: Size(495, 481),
      sourceRect: Rect.fromLTWH(2, 0, 490, 481),
      screen: Rect.fromLTRB(0.106, 0.108, 0.730, 0.603),
      slot: Rect.fromLTRB(0.250, 0.820, 0.750, 0.865),
      keys: Rect.fromLTRB(0.255, 0.900, 0.690, 0.960),
      remote: Rect.fromLTRB(0.76, 0.14, 0.96, 0.52),
      full: Rect.fromLTRB(0.82, 0.78, 0.96, 0.92),
    ),
    CrtTvSkin.knob2 => const CrtSpriteLayout(
      asset: 'assets/knob2.png',
      assetSize: Size(498, 477),
      sourceRect: Rect.fromLTWH(3, 2, 493, 475),
      screen: Rect.fromLTRB(0.106, 0.108, 0.728, 0.602),
      slot: Rect.fromLTRB(0.220, 0.770, 0.740, 0.845),
      keys: Rect.fromLTRB(0.250, 0.880, 0.660, 0.945),
      remote: Rect.fromLTRB(0.76, 0.14, 0.96, 0.52),
      full: Rect.fromLTRB(0.82, 0.78, 0.96, 0.92),
    ),
  };
}
