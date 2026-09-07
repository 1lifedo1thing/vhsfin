import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/state/shelf_display_prefs.dart';

/// Deck chrome under the entertainment center — filters, experience, account.
class DeckSettingsBar extends StatelessWidget {
  const DeckSettingsBar({
    super.key,
    required this.connected,
    required this.onCollection,
    required this.onConnect,
    required this.onSignOut,
    required this.vhsOnly,
    required this.sortLabel,
    required this.onVhsOnlyChanged,
    required this.onOpenSort,
    required this.saveTimestampOnEject,
    required this.onSaveTimestampChanged,
    required this.onReplayArtGrab,
    this.userName,
    this.embedded = false,
  });

  final bool connected;
  final String? userName;
  final bool vhsOnly;
  final String sortLabel;
  final bool saveTimestampOnEject;
  final VoidCallback onCollection;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;
  final ValueChanged<bool> onVhsOnlyChanged;
  final VoidCallback onOpenSort;
  final ValueChanged<bool> onSaveTimestampChanged;
  final VoidCallback onReplayArtGrab;

  /// When true, sits flush as the lower drawer of the wooden console.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(embedded ? 6 : 10),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF4A4A4E),
            Color(0xFF2E2E32),
            Color(0xFF1A1A1E),
          ],
        ),
        border: Border.all(
          color: embedded
              ? const Color(0xFF5A5A60)
              : Colors.black.withValues(alpha: 0.55),
        ),
        boxShadow: embedded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.04),
                  blurRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: vhsOnly ? VhsColors.ledOn : VhsColors.ledOff,
                  boxShadow: vhsOnly
                      ? [
                          BoxShadow(
                            color: VhsColors.ledOn.withValues(alpha: 0.45),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DECK SETTINGS',
                style: TextStyle(
                  color: VhsColors.phosphor.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                ),
              ),
              const Spacer(),
              Text(
                'VHSFIN',
                style: TextStyle(
                  color: VhsColors.brand.withValues(alpha: 0.35),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _DeckToggle(
                  label: 'VHS ONLY',
                  value: vhsOnly,
                  onChanged: onVhsOnlyChanged,
                ),
                _DeckToggle(
                  label: 'SAVE ON EJECT',
                  value: saveTimestampOnEject,
                  onChanged: onSaveTimestampChanged,
                ),
                _DeckKey(
                  label: 'SORT',
                  sublabel: sortLabel,
                  onPressed: onOpenSort,
                ),
                _DeckKey(
                  label: 'COLLECTION',
                  onPressed: onCollection,
                ),
                _DeckKey(
                  label: 'REPLAY ART GRAB',
                  onPressed: onReplayArtGrab,
                ),
                _DeckKey(
                  label: connected ? 'SIGN OUT' : 'CONNECT',
                  sublabel: connected ? userName : null,
                  dim: true,
                  onPressed: connected ? onSignOut : onConnect,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save on eject remembers where you left each tape — reinsert '
            'to continue (then rewind like a real VHS). Replay art grab '
            're-runs the first-time poster lookup tour.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: VhsColors.brand.withValues(alpha: 0.4),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );

    if (embedded) return panel;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: panel,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
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
              const SizedBox(width: 6),
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
          constraints: const BoxConstraints(minWidth: 96, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
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
