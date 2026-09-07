/// Selectable classic CRT TV bezels for the living-room deck.
enum CrtTvSkin {
  /// Charcoal Zenith-style all-in-one (default).
  zenith,

  /// Cream / putty 80s–90s consumer plastic.
  consumerCream,

  /// Compact portable with a carry handle vibe.
  portable,

  /// Warm walnut wood-console cabinet.
  woodConsole,
}

extension CrtTvSkinLabels on CrtTvSkin {
  String get settingsLabel => switch (this) {
        CrtTvSkin.zenith => 'ZENITH',
        CrtTvSkin.consumerCream => 'CREAM',
        CrtTvSkin.portable => 'PORTABLE',
        CrtTvSkin.woodConsole => 'WOOD',
      };

  String get menuTitle => switch (this) {
        CrtTvSkin.zenith => 'Zenith charcoal',
        CrtTvSkin.consumerCream => '80s cream plastic',
        CrtTvSkin.portable => 'Portable set',
        CrtTvSkin.woodConsole => 'Wood console',
      };
}
