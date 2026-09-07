import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';

/// Deck / experience settings as a bottom sheet (no Riverpod).
Future<void> showDeckSettingsSheet(
  BuildContext context, {
  required bool connected,
  required bool vhsOnly,
  required String sortLabel,
  required bool saveTimestampOnEject,
  required CrtTvSkin crtSkin,
  required VoidCallback onCollection,
  required VoidCallback onConnect,
  required VoidCallback onSignOut,
  required ValueChanged<bool> onVhsOnlyChanged,
  required VoidCallback onOpenSort,
  required ValueChanged<bool> onSaveTimestampChanged,
  required ValueChanged<CrtTvSkin> onCrtSkinChanged,
  String? userName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _DeckSettingsSheet(
      connected: connected,
      userName: userName,
      vhsOnly: vhsOnly,
      sortLabel: sortLabel,
      saveTimestampOnEject: saveTimestampOnEject,
      crtSkin: crtSkin,
      onCollection: onCollection,
      onConnect: onConnect,
      onSignOut: onSignOut,
      onVhsOnlyChanged: onVhsOnlyChanged,
      onOpenSort: onOpenSort,
      onSaveTimestampChanged: onSaveTimestampChanged,
      onCrtSkinChanged: onCrtSkinChanged,
    ),
  );
}

class _DeckSettingsSheet extends StatefulWidget {
  const _DeckSettingsSheet({
    required this.connected,
    required this.vhsOnly,
    required this.sortLabel,
    required this.saveTimestampOnEject,
    required this.crtSkin,
    required this.onCollection,
    required this.onConnect,
    required this.onSignOut,
    required this.onVhsOnlyChanged,
    required this.onOpenSort,
    required this.onSaveTimestampChanged,
    required this.onCrtSkinChanged,
    this.userName,
  });

  final bool connected;
  final String? userName;
  final bool vhsOnly;
  final String sortLabel;
  final bool saveTimestampOnEject;
  final CrtTvSkin crtSkin;
  final VoidCallback onCollection;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;
  final ValueChanged<bool> onVhsOnlyChanged;
  final VoidCallback onOpenSort;
  final ValueChanged<bool> onSaveTimestampChanged;
  final ValueChanged<CrtTvSkin> onCrtSkinChanged;

  @override
  State<_DeckSettingsSheet> createState() => _DeckSettingsSheetState();
}

class _DeckSettingsSheetState extends State<_DeckSettingsSheet> {
  late bool _vhsOnly = widget.vhsOnly;
  late bool _saveOnEject = widget.saveTimestampOnEject;
  late CrtTvSkin _crtSkin = widget.crtSkin;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: const Color(0xFF1A1A1E),
            borderRadius: BorderRadius.circular(14),
            elevation: 18,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF2E2E32), Color(0xFF141418)],
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
                            color:
                                _vhsOnly ? VhsColors.ledOn : VhsColors.ledOff,
                            boxShadow: _vhsOnly
                                ? [
                                    BoxShadow(
                                      color: VhsColors.ledOn
                                          .withValues(alpha: 0.45),
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
                            color: VhsColors.phosphor.withValues(alpha: 0.75),
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
                            color: VhsColors.brand.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _DeckToggle(
                      label: 'VHS ONLY',
                      value: _vhsOnly,
                      onChanged: (value) {
                        setState(() => _vhsOnly = value);
                        widget.onVhsOnlyChanged(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    _DeckToggle(
                      label: 'SAVE ON EJECT',
                      value: _saveOnEject,
                      onChanged: (value) {
                        setState(() => _saveOnEject = value);
                        widget.onSaveTimestampChanged(value);
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
                    Text(
                      'CRT LOOK',
                      style: TextStyle(
                        color: VhsColors.phosphor.withValues(alpha: 0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final skin in CrtTvSkin.values)
                          _SkinChip(
                            label: skin.settingsLabel,
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
                            sublabel: widget.connected ? widget.userName : null,
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
                    const SizedBox(height: 10),
                    Text(
                      'Save on eject remembers where you left each tape — '
                      'reinsert to continue (then rewind like a real VHS).',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: VhsColors.brand.withValues(alpha: 0.4),
                        fontSize: 11,
                        height: 1.35,
                      ),
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

class _SkinChip extends StatelessWidget {
  const _SkinChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF243528) : const Color(0xFF222226),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? VhsColors.phosphor.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? VhsColors.phosphor
                  : VhsColors.brand.withValues(alpha: 0.7),
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckToggle extends StatelessWidget {
  const _DeckToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: value ? const Color(0xFF243528) : const Color(0xFF222226),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: value
                  ? VhsColors.phosphor.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: value
                        ? VhsColors.phosphor
                        : VhsColors.brand.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Text(
                value ? 'ON' : 'OFF',
                style: TextStyle(
                  color: value
                      ? VhsColors.phosphor.withValues(alpha: 0.75)
                      : VhsColors.brand.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 1,
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: VhsColors.phosphor,
                activeTrackColor: VhsColors.phosphorDim,
                inactiveThumbColor: VhsColors.brand.withValues(alpha: 0.7),
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
        ? VhsColors.brand.withValues(alpha: 0.55)
        : VhsColors.phosphor.withValues(alpha: 0.9);

    return Material(
      color: const Color(0xFF222226),
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
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
              if (sublabel != null && sublabel!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  sublabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: VhsColors.brand.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
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
    builder: (context) => _ShelfSortSheet(
      current: current,
      onSelect: onSelect,
    ),
  );
}

class _ShelfSortSheet extends StatelessWidget {
  const _ShelfSortSheet({
    required this.current,
    required this.onSelect,
  });

  final ShelfSortMode current;
  final ValueChanged<ShelfSortMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: const Color(0xFF2A1810),
            borderRadius: BorderRadius.circular(14),
            elevation: 18,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.45)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A2418), Color(0xFF1A100C)],
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
                              color: VhsColors.phosphor.withValues(alpha: 0.8),
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
                            color: VhsColors.brand.withValues(alpha: 0.55),
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
                      ? VhsColors.phosphor
                      : VhsColors.brand.withValues(alpha: 0.85),
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
                color: VhsColors.phosphor.withValues(alpha: 0.9),
              ),
          ],
        ),
      ),
    );
  }
}
