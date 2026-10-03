import 'package:flutter/material.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';
import 'package:vhsfin/features/living_room/model/crt_sprite_layout.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';
import 'package:vhsfin/features/living_room/widgets/cabinet_material.dart';
import 'package:vhsfin/features/living_room/widgets/crt_sprite_bezel.dart';
import 'package:vhsfin/features/living_room/widgets/deck_panel.dart';

/// Deck / experience settings as a VCR front panel (no Riverpod).
Future<void> showDeckSettingsSheet(
  BuildContext context, {
  required bool connected,
  required bool vhsOnly,
  required String sortLabel,
  required bool saveTimestampOnEject,
  required bool jellyfinPosters,
  required bool soundEffects,
  required ValueChanged<bool> onSoundEffectsChanged,
  required ValueChanged<bool> onJellyfinPostersChanged,
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
  return showDeckPanelSheet<void>(
    context,
    builder: (context) => _DeckSettingsSheet(
      connected: connected,
      userName: userName,
      vhsOnly: vhsOnly,
      sortLabel: sortLabel,
      saveTimestampOnEject: saveTimestampOnEject,
      jellyfinPosters: jellyfinPosters,
      soundEffects: soundEffects,
      onSoundEffectsChanged: onSoundEffectsChanged,
      onJellyfinPostersChanged: onJellyfinPostersChanged,
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
  );
}

class _DeckSettingsSheet extends StatefulWidget {
  const _DeckSettingsSheet({
    required this.connected,
    required this.vhsOnly,
    required this.sortLabel,
    required this.saveTimestampOnEject,
    required this.jellyfinPosters,
    required this.soundEffects,
    required this.onSoundEffectsChanged,
    required this.onJellyfinPostersChanged,
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
  final bool jellyfinPosters;
  final bool soundEffects;
  final ValueChanged<bool> onSoundEffectsChanged;
  final ValueChanged<bool> onJellyfinPostersChanged;
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
  late bool _jellyfinPosters = widget.jellyfinPosters;
  late bool _sound = widget.soundEffects;
  late CrtTvSkin _crtSkin = widget.crtSkin;
  late CabinetStyle _cabinet = widget.cabinetStyle;

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final user = widget.userName?.trim();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeckSheetHeader(title: 'SETTINGS', onClose: _close),
        const DeckLabel('SHELF'),
        Row(
          children: [
            for (final style in CabinetStyle.values) ...[
              if (style != CabinetStyle.values.first) const SizedBox(width: 10),
              Expanded(
                child: DeckBay(
                  label: style.settingsLabel,
                  semanticLabel: style.menuTitle,
                  selected: style == _cabinet,
                  onTap: () {
                    setState(() => _cabinet = style);
                    widget.onCabinetStyleChanged(style);
                  },
                  child: _ShelfPreview(style: style),
                ),
              ),
            ],
          ],
        ),
        const DeckLabel('TV'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.02,
          children: [
            for (final skin in selectableCrtTvSkins)
              DeckBay(
                label: skin.settingsLabel,
                semanticLabel: skin.menuTitle,
                selected: skin == _crtSkin,
                onTap: () {
                  setState(() => _crtSkin = skin);
                  widget.onCrtSkinChanged(skin);
                },
                child: Expanded(child: _TvPreview(skin: skin)),
              ),
          ],
        ),
        const DeckLabel('OPTIONS'),
        DeckOptionRow(
          label: 'VHS ONLY',
          subtitle: 'Only titles with scanned VHS artwork.',
          value: _vhsOnly,
          onChanged: (value) {
            setState(() => _vhsOnly = value);
            widget.onVhsOnlyChanged(value);
          },
        ),
        const SizedBox(height: 8),
        DeckOptionRow(
          label: 'SAVE ON EJECT',
          subtitle: 'Keeps your place. Rewinding is still on you.',
          value: _saveOnEject,
          onChanged: (value) {
            setState(() => _saveOnEject = value);
            widget.onSaveTimestampChanged(value);
          },
        ),
        const SizedBox(height: 8),
        DeckOptionRow(
          label: 'JELLYFIN POSTERS',
          subtitle: 'Instead of the scanned VHS box.',
          value: _jellyfinPosters,
          onChanged: (value) {
            setState(() => _jellyfinPosters = value);
            widget.onJellyfinPostersChanged(value);
          },
        ),
        const SizedBox(height: 8),
        DeckOptionRow(
          label: 'SOUND EFFECTS',
          value: _sound,
          onChanged: (value) {
            setState(() => _sound = value);
            widget.onSoundEffectsChanged(value);
          },
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DeckHardKey(
                label: 'SORT',
                sublabel: widget.sortLabel,
                onPressed: () {
                  _close();
                  widget.onOpenSort();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DeckHardKey(
                label: 'SHELVES',
                sublabel: 'PICK',
                semanticLabel: 'Choose shelves',
                onPressed: () {
                  _close();
                  widget.onCollection();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DeckHardKey(
                label: widget.connected ? 'SIGN OUT' : 'SIGN IN',
                sublabel: widget.connected
                    ? (user != null && user.isNotEmpty ? user : 'JELLYFIN')
                    : 'JELLYFIN',
                tone: widget.connected ? DeckKeyTone.grey : DeckKeyTone.record,
                onPressed: () {
                  _close();
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
    );
  }
}

/// A tiny live shelf rendered in [style] — the preview is the real material.
class _ShelfPreview extends StatelessWidget {
  const _ShelfPreview({required this.style});

  final CabinetStyle style;

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
    return CabinetScope(
      style: style,
      child: SizedBox(
        height: 46,
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
            const CabinetLedge(height: 6),
          ],
        ),
      ),
    );
  }
}

/// The cabinet art itself, as it sits in the living room.
class _TvPreview extends StatelessWidget {
  const _TvPreview({required this.skin});

  final CrtTvSkin skin;

  @override
  Widget build(BuildContext context) {
    final src = CrtSpriteLayout.of(skin).sourceRect;
    return FittedBox(
      child: SizedBox(
        width: src.width,
        height: src.height,
        child: CrtSpriteBezel(skin: skin),
      ),
    );
  }
}

/// Shelf order picker, on the same deck panel.
Future<void> showShelfSortSheet(
  BuildContext context, {
  required ShelfSortMode current,
  required ValueChanged<ShelfSortMode> onSelect,
}) {
  return showDeckPanelSheet<void>(
    context,
    maxWidth: 420,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeckSheetHeader(
          title: 'SORT',
          detail: current.buttonLabel,
          onClose: () => Navigator.of(context).pop(),
        ),
        const DeckLabel('SHELF ORDER'),
        for (final mode in ShelfSortMode.values) ...[
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
      ],
    ),
  );
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
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: DeckPressable(
        onTap: onTap,
        haptic: DeckFeedback.select,
        builder: (context, pressed) => Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: pressed ? const Color(0x0DFFFFFF) : const Color(0x05FFFFFF),
            border: Border.all(color: const Color(0x0DFFFFFF)),
          ),
          child: Row(
            children: [
              DeckLed(on: selected),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? VhsColors.accent
                        : const Color(0xFFD9E0E2),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
