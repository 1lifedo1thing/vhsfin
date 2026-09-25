import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';
import 'package:vhsfin/features/living_room/model/crt_sprite_layout.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/widgets/cabinet_material.dart';
import 'package:vhsfin/features/living_room/widgets/crt_sprite_bezel.dart';

/// Deck / experience settings as a bottom sheet (no Riverpod).
Future<void> showDeckSettingsSheet(
  BuildContext context, {
  required bool connected,
  required bool vhsOnly,
  required String sortLabel,
  required bool saveTimestampOnEject,
  required bool vhsCovers,
  required ValueChanged<bool> onVhsCoversChanged,
  required CrtTvSkin crtSkin,
  required VoidCallback onCollection,
  required VoidCallback onConnect,
  required VoidCallback onSignOut,
  required ValueChanged<bool> onVhsOnlyChanged,
  required VoidCallback onOpenSort,
  required ValueChanged<bool> onSaveTimestampChanged,
  required ValueChanged<CrtTvSkin> onCrtSkinChanged,
  required CabinetStyle cabinetStyle,
  required ValueChanged<CabinetStyle> onCabinetStyleChanged,
  String? userName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => DismissOnEscape(
      child: _DeckSettingsSheet(
        connected: connected,
        userName: userName,
        vhsOnly: vhsOnly,
        sortLabel: sortLabel,
        saveTimestampOnEject: saveTimestampOnEject,
        vhsCovers: vhsCovers,
        onVhsCoversChanged: onVhsCoversChanged,
        crtSkin: crtSkin,
        onCollection: onCollection,
        onConnect: onConnect,
        onSignOut: onSignOut,
        onVhsOnlyChanged: onVhsOnlyChanged,
        onOpenSort: onOpenSort,
        onSaveTimestampChanged: onSaveTimestampChanged,
        onCrtSkinChanged: onCrtSkinChanged,
        cabinetStyle: cabinetStyle,
        onCabinetStyleChanged: onCabinetStyleChanged,
      ),
    ),
  );
}

class _DeckSettingsSheet extends StatefulWidget {
  const _DeckSettingsSheet({
    required this.connected,
    required this.vhsOnly,
    required this.sortLabel,
    required this.saveTimestampOnEject,
    required this.vhsCovers,
    required this.onVhsCoversChanged,
    required this.crtSkin,
    required this.onCollection,
    required this.onConnect,
    required this.onSignOut,
    required this.onVhsOnlyChanged,
    required this.onOpenSort,
    required this.onSaveTimestampChanged,
    required this.onCrtSkinChanged,
    required this.cabinetStyle,
    required this.onCabinetStyleChanged,
    this.userName,
  });

  final bool connected;
  final String? userName;
  final bool vhsOnly;
  final String sortLabel;
  final bool saveTimestampOnEject;
  final bool vhsCovers;
  final ValueChanged<bool> onVhsCoversChanged;
  final CrtTvSkin crtSkin;
  final VoidCallback onCollection;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;
  final ValueChanged<bool> onVhsOnlyChanged;
  final VoidCallback onOpenSort;
  final ValueChanged<bool> onSaveTimestampChanged;
  final ValueChanged<CrtTvSkin> onCrtSkinChanged;
  final CabinetStyle cabinetStyle;
  final ValueChanged<CabinetStyle> onCabinetStyleChanged;

  @override
  State<_DeckSettingsSheet> createState() => _DeckSettingsSheetState();
}

class _DeckSettingsSheetState extends State<_DeckSettingsSheet> {
  late bool _vhsOnly = widget.vhsOnly;
  late bool _saveOnEject = widget.saveTimestampOnEject;
  late bool _vhsCovers = widget.vhsCovers;
  late CrtTvSkin _crtSkin = widget.crtSkin;
  late CabinetStyle _cabinet = widget.cabinetStyle;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: Material(
            color: VhsColors.surface,
            borderRadius: BorderRadius.circular(14),
            elevation: 18,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [VhsColors.surfaceRaised, VhsColors.surface],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _vhsOnly
                                ? VhsColors.ledOn
                                : VhsColors.ledOff,
                            boxShadow: _vhsOnly
                                ? [
                                    BoxShadow(
                                      color: VhsColors.ledOn.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'SETTINGS',
                          style: TextStyle(
                            color: VhsColors.accent.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: VhsColors.ink.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DeckToggle(
                      label: 'VHS ONLY',
                      subtitle: 'Only titles with scanned VHS artwork.',
                      value: _vhsOnly,
                      onChanged: (value) {
                        setState(() => _vhsOnly = value);
                        widget.onVhsOnlyChanged(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    _DeckToggle(
                      label: 'SAVE ON EJECT',
                      subtitle: 'Keeps your place. Rewinding is still on you.',
                      value: _saveOnEject,
                      onChanged: (value) {
                        setState(() => _saveOnEject = value);
                        widget.onSaveTimestampChanged(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    _DeckToggle(
                      label: 'VHS COVERS',
                      subtitle: 'Show the scanned VHS front when the whole sleeve is available.',
                      value: _vhsCovers,
                      onChanged: (value) {
                        setState(() => _vhsCovers = value);
                        widget.onVhsCoversChanged(value);
                      },
                    ),
                    const SizedBox(height: 10),
                    _DeckKey(
                      label: 'SORT',
                      sublabel: widget.sortLabel,
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onOpenSort();
                      },
                    ),
                    const SizedBox(height: 14),
                    const _SectionLabel('SHELF'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final style in CabinetStyle.values) ...[
                          if (style != CabinetStyle.values.first)
                            const SizedBox(width: 6),
                          Expanded(
                            child: _CabinetThumb(
                              style: style,
                              selected: style == _cabinet,
                              onTap: () {
                                setState(() => _cabinet = style);
                                widget.onCabinetStyleChanged(style);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _SectionLabel('TV'),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.12,
                      children: [
                        for (final skin in CrtTvSkin.values)
                          _SkinThumb(
                            skin: skin,
                            selected: skin == _crtSkin,
                            onTap: () {
                              setState(() => _crtSkin = skin);
                              widget.onCrtSkinChanged(skin);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _DeckKey(
                            label: 'COLLECTION',
                            onPressed: () {
                              Navigator.of(context).pop();
                              widget.onCollection();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _DeckKey(
                            label: widget.connected ? 'SIGN OUT' : 'CONNECT',
                            // Always reserve subtitle height so both keys match.
                            sublabel: widget.connected
                                ? (widget.userName?.isNotEmpty == true
                                      ? widget.userName
                                      : ' ')
                                : ' ',
                            dim: true,
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (widget.connected) {
                                widget.onSignOut();
                              } else {
                                widget.onConnect();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: VhsColors.accent.withValues(alpha: 0.75),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
    ),
  );
}

/// A tiny live shelf rendered in [style] — the preview is the real material.
class _CabinetThumb extends StatelessWidget {
  const _CabinetThumb({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final CabinetStyle style;
  final bool selected;
  final VoidCallback onTap;

  static const _spines = [
    Color(0xFF5B4BC4),
    Color(0xFFD94A3A),
    Color(0xFFE8DCC0),
    Color(0xFF2F6FD6),
    Color(0xFF1F1F22),
    Color(0xFFE0A030),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: style.menuTitle,
      child: Material(
        color: selected ? VhsColors.accentWash : VhsColors.surfaceRaised,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: selected
                    ? VhsColors.accent.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                CabinetScope(
                  style: style,
                  child: SizedBox(
                    height: 52,
                    child: Column(
                      children: [
                        Expanded(
                          child: CabinetPanel(
                            recessed: true,
                            grain: const Alignment(-0.4, 0.3),
                            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final c in _spines) ...[
                                  Container(
                                    width: 7,
                                    decoration: BoxDecoration(
                                      color: c,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 1.5),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const CabinetLedge(height: 7),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  style.settingsLabel,
                  style: TextStyle(
                    color: selected
                        ? VhsColors.accent
                        : VhsColors.ink.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkinThumb extends StatelessWidget {
  const _SkinThumb({
    required this.skin,
    required this.selected,
    required this.onTap,
  });

  final CrtTvSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? VhsColors.accentWash : VhsColors.surfaceRaised,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? VhsColors.accent.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: Colors.black,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: CrtSpriteLayout.of(skin).sourceRect.width,
                      height: CrtSpriteLayout.of(skin).sourceRect.height,
                      child: CrtSpriteBezel(skin: skin),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                skin.settingsLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? VhsColors.accent
                      : VhsColors.ink.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckToggle extends StatelessWidget {
  const _DeckToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? VhsColors.accentWash : VhsColors.surfaceRaised,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: value
                  ? VhsColors.accent.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: value
                            ? VhsColors.accent
                            : VhsColors.ink.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: VhsColors.ink.withValues(alpha: 0.45),
                        fontSize: 10,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value ? 'ON' : 'OFF',
                style: TextStyle(
                  color: value
                      ? VhsColors.accent.withValues(alpha: 0.75)
                      : VhsColors.ink.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: VhsColors.accent,
                activeTrackColor: VhsColors.accentDim,
                inactiveThumbColor: VhsColors.ink.withValues(alpha: 0.7),
                inactiveTrackColor: Colors.black.withValues(alpha: 0.45),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeckKey extends StatelessWidget {
  const _DeckKey({
    required this.label,
    required this.onPressed,
    this.sublabel,
    this.dim = false,
  });

  final String label;
  final String? sublabel;
  final VoidCallback onPressed;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final fg = dim
        ? VhsColors.ink.withValues(alpha: 0.55)
        : VhsColors.accent.withValues(alpha: 0.9);

    return Material(
      color: VhsColors.surfaceRaised,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                (sublabel != null && sublabel!.trim().isNotEmpty)
                    ? sublabel!
                    : ' ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: (sublabel != null && sublabel!.trim().isNotEmpty)
                      ? VhsColors.ink.withValues(alpha: 0.45)
                      : Colors.transparent,
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showShelfSortSheet(
  BuildContext context, {
  required ShelfSortMode current,
  required ValueChanged<ShelfSortMode> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => DismissOnEscape(
      child: _ShelfSortSheet(current: current, onSelect: onSelect),
    ),
  );
}

class _ShelfSortSheet extends StatelessWidget {
  const _ShelfSortSheet({required this.current, required this.onSelect});

  final ShelfSortMode current;
  final ValueChanged<ShelfSortMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: VhsColors.surface,
            borderRadius: BorderRadius.circular(14),
            elevation: 18,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.45)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [VhsColors.surfaceRaised, VhsColors.surface],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'SORT BY',
                            style: TextStyle(
                              color: VhsColors.accent.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: VhsColors.ink.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final mode in ShelfSortMode.values)
                    _SortOption(
                      label: mode.menuTitle,
                      selected: mode == current,
                      onTap: () {
                        onSelect(mode);
                        Navigator.of(context).pop();
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? VhsColors.accent
                      : VhsColors.ink.withValues(alpha: 0.85),
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_rounded,
                size: 20,
                color: VhsColors.accent.withValues(alpha: 0.9),
              ),
          ],
        ),
      ),
    );
  }
}
