/// Furniture look for the TV stand and tape shelves.
enum CabinetStyle {
  /// Photographic walnut veneer with lit edges (default).
  walnut,

  /// Matte charcoal panels — quiet, lets the tapes carry the colour.
  flat,
}

extension CabinetStyleLabels on CabinetStyle {
  String get settingsLabel => switch (this) {
    CabinetStyle.flat => 'FLAT',
    CabinetStyle.walnut => 'WALNUT',
  };

  String get menuTitle => switch (this) {
    CabinetStyle.flat => 'Flat charcoal shelves',
    CabinetStyle.walnut => 'Walnut wood shelves',
  };

  static CabinetStyle fromPrefs(String? raw) {
    for (final style in CabinetStyle.values) {
      if (style.name == raw) return style;
    }
    return CabinetStyle.walnut;
  }
}
