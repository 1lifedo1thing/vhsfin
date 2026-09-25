/// Selectable CRT cabinets for the living-room deck.
enum CrtTvSkin {
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

extension CrtTvSkinLabels on CrtTvSkin {
  String get settingsLabel => switch (this) {
    CrtTvSkin.crt90s => '90S',
    CrtTvSkin.graphite => 'GRAPHITE',
    CrtTvSkin.ivory => 'IVORY',
    CrtTvSkin.crimson => 'CRIMSON',
    CrtTvSkin.knob => 'KNOBS',
    CrtTvSkin.knob2 => 'PUTTY',
  };

  String get menuTitle => switch (this) {
    CrtTvSkin.crt90s => 'Late-90s TV / VCR',
    CrtTvSkin.graphite => 'Graphite portable',
    CrtTvSkin.ivory => 'Ivory portable',
    CrtTvSkin.crimson => 'Crimson portable',
    CrtTvSkin.knob => 'Walnut on charcoal deck',
    CrtTvSkin.knob2 => 'Walnut on putty deck',
  };

  /// Map current and legacy prefs keys onto the six cabinets.
  static CrtTvSkin fromPrefs(String? raw) {
    return switch (raw) {
      'crt90s' || 'skeuomorphic' || 'zenith' => CrtTvSkin.crt90s,
      'graphite' => CrtTvSkin.graphite,
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
      _ => CrtTvSkin.crt90s,
    };
  }
}
