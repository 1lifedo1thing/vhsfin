/// Selectable classic CRT TV bezels for the living-room deck.
enum CrtTvSkin {
  /// Photographic late-90s TV/VCR cabinet with integrated transport keys.
  skeuomorphic,

  /// Original charcoal Zenith-style all-in-one.
  zenith,

  /// Late-90s silver WEGA / flat-tube look with a squircle screen.
  wegaSilver,

  /// Deep bubble tube — heavy rounded CRT aperture like a classic curved set.
  bubbleTube,

  /// 90s teal / graphite sports-set plastic.
  aquaGraphite,
}

extension CrtTvSkinLabels on CrtTvSkin {
  String get settingsLabel => switch (this) {
    CrtTvSkin.skeuomorphic => 'SKEUOMORPHIC',
    CrtTvSkin.zenith => 'ZENITH',
    CrtTvSkin.wegaSilver => 'WEGA',
    CrtTvSkin.bubbleTube => 'TUBE',
    CrtTvSkin.aquaGraphite => 'AQUA',
  };

  String get menuTitle => switch (this) {
    CrtTvSkin.skeuomorphic => 'Late-90s TV / VCR',
    CrtTvSkin.zenith => 'Zenith charcoal',
    CrtTvSkin.wegaSilver => '90s silver WEGA',
    CrtTvSkin.bubbleTube => 'Bubble tube',
    CrtTvSkin.aquaGraphite => 'Aqua graphite',
  };

  /// Map legacy prefs keys from earlier skin names.
  static CrtTvSkin fromPrefs(String? raw) {
    return switch (raw) {
      'skeuomorphic' => CrtTvSkin.skeuomorphic,
      'zenith' => CrtTvSkin.zenith,
      'wegaSilver' || 'consumerCream' => CrtTvSkin.wegaSilver,
      'bubbleTube' || 'portable' => CrtTvSkin.bubbleTube,
      'aquaGraphite' || 'woodConsole' => CrtTvSkin.aquaGraphite,
      _ => CrtTvSkin.skeuomorphic,
    };
  }
}
