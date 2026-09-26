/// Selectable CRT cabinets for the living-room deck.
enum CrtTvSkin {
  /// Dark metal TV/VCR derived from the app icon.
  crtIcon,

  /// Late-90s TV/VCR combo (`assets/branding/crt-90s.png`).
  crt90s,

  graphite,
  ivory,
  crimson,

  /// Wood CRT on a charcoal deck (`assets/knob.png`).
  knob,

  /// Wood CRT on a putty deck (`assets/knob2.png`).
  knob2,
}

/// The six cabinets offered in the TV picker, in display order.
const selectableCrtTvSkins = <CrtTvSkin>[
  CrtTvSkin.crtIcon,
  CrtTvSkin.crt90s,
  CrtTvSkin.ivory,
  CrtTvSkin.crimson,
  CrtTvSkin.knob,
  CrtTvSkin.knob2,
];

extension CrtTvSkinLabels on CrtTvSkin {
  String get settingsLabel => switch (this) {
    CrtTvSkin.crt90s => '90S',
    CrtTvSkin.crtIcon => 'ICON',
    CrtTvSkin.graphite => 'GRAPHITE',
    CrtTvSkin.ivory => 'IVORY',
    CrtTvSkin.crimson => 'CRIMSON',
    CrtTvSkin.knob => 'KNOBS',
    CrtTvSkin.knob2 => 'PUTTY',
  };

  String get menuTitle => switch (this) {
    CrtTvSkin.crt90s => 'Late-90s TV / VCR',
    CrtTvSkin.crtIcon => 'Dark metal TV / VCR',
    CrtTvSkin.graphite => 'Graphite portable',
    CrtTvSkin.ivory => 'Ivory portable',
    CrtTvSkin.crimson => 'Crimson portable',
    CrtTvSkin.knob => 'Walnut on charcoal deck',
    CrtTvSkin.knob2 => 'Walnut on putty deck',
  };

  /// How much of the art's width the cabinet itself fills; the rest is
  /// transparent edge. Lets the layout size the TV by its body.
  double get bodyWidthFraction => switch (this) {
    CrtTvSkin.crtIcon => 0.943,
    CrtTvSkin.crt90s => 0.983,
    _ => 1,
  };

  /// Map current and legacy prefs keys onto the available cabinets.
  static CrtTvSkin fromPrefs(String? raw) {
    return switch (raw) {
      'crt90s' || 'skeuomorphic' || 'zenith' => CrtTvSkin.crt90s,
      'crtIcon' => CrtTvSkin.crtIcon,
      'graphite' => CrtTvSkin.crtIcon,
      'ivory' ||
      'bubbleTube' ||
      'portable' ||
      'silver' ||
      'wegaSilver' ||
      'consumerCream' ||
      'beige' => CrtTvSkin.ivory,
      'crimson' || 'aquaGraphite' => CrtTvSkin.crimson,
      'knob' || 'walnutKnobs' || 'woodConsole' => CrtTvSkin.knob,
      'knob2' || 'walnutGrille' => CrtTvSkin.knob2,
      _ => CrtTvSkin.crtIcon,
    };
  }
}
