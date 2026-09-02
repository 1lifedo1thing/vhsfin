import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/shelf_display_prefs.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/living_room/presentation/bookshelf_view.dart';
import 'package:vhsfin/features/living_room/presentation/vcr_box.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_remote.dart';

class LivingRoomPage extends ConsumerWidget {
  const LivingRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final displayPrefs = ref.watch(shelfDisplayPrefsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => showVhsRemote(context),
        backgroundColor: const Color(0xFF2A2A28),
        foregroundColor: VhsColors.brand,
        tooltip: 'Remote',
        child: const Icon(Icons.settings_remote_rounded),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              Color(0xFF3A2418),
              VhsColors.woodDeep,
              Color(0xFF070504),
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 820;
              final pad = wide ? constraints.maxWidth * 0.14 : 16.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(pad, 20, pad, 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _EntertainmentCenter(),
                    const SizedBox(height: 20),
                    _BottomBar(
                      connected: session != null,
                      userName: session?.userName,
                      vhsOnly: displayPrefs.vhsOnly,
                      sortLabel: displayPrefs.sort.buttonLabel,
                      onCollection: () => context.push('/libraries'),
                      onConnect: () => context.push('/connect'),
                      onSignOut: () =>
                          ref.read(sessionProvider.notifier).signOut(),
                      onVhsOnlyChanged: (value) => ref
                          .read(shelfDisplayPrefsProvider.notifier)
                          .setVhsOnly(value),
                      onOpenSort: () => showShelfSortSheet(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// VCR sitting on a wooden console with the tape shelf built into it.
class _EntertainmentCenter extends StatelessWidget {
  const _EntertainmentCenter();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5A3A24),
            Color(0xFF3A2416),
            Color(0xFF24160E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: VcrBox(),
          ),
          SizedBox(height: 14),
          BookshelfView(embedded: true),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.connected,
    required this.onCollection,
    required this.onConnect,
    required this.onSignOut,
    required this.vhsOnly,
    required this.sortLabel,
    required this.onVhsOnlyChanged,
    required this.onOpenSort,
    this.userName,
  });

  final bool connected;
  final String? userName;
  final bool vhsOnly;
  final String sortLabel;
  final VoidCallback onCollection;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;
  final ValueChanged<bool> onVhsOnlyChanged;
  final VoidCallback onOpenSort;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _VhsOnlySwitch(
          value: vhsOnly,
          onChanged: onVhsOnlyChanged,
        ),
        _dot(),
        _BarLink(
          label: 'SORT · $sortLabel ▾',
          onPressed: onOpenSort,
        ),
        _dot(),
        _BarLink(
          label: 'COLLECTION',
          onPressed: onCollection,
        ),
        _dot(),
        _BarLink(
          label: connected
              ? 'SIGN OUT${userName != null ? ' ($userName)' : ''}'
              : 'CONNECT',
          dim: true,
          onPressed: connected ? onSignOut : onConnect,
        ),
      ],
    );
  }

  Widget _dot() {
    return Text(
      '·',
      style: TextStyle(
        color: VhsColors.brand.withValues(alpha: 0.35),
      ),
    );
  }
}

class _VhsOnlySwitch extends StatelessWidget {
  const _VhsOnlySwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VHS ONLY',
                style: TextStyle(
                  color: value
                      ? VhsColors.phosphor.withValues(alpha: 0.95)
                      : VhsColors.brand.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value ? 'ON' : 'OFF',
                style: TextStyle(
                  color: value
                      ? VhsColors.phosphor.withValues(alpha: 0.7)
                      : VhsColors.brand.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 4),
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

class _BarLink extends StatelessWidget {
  const _BarLink({
    required this.label,
    required this.onPressed,
    this.dim = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final color = dim
        ? VhsColors.brand.withValues(alpha: 0.55)
        : VhsColors.phosphor.withValues(alpha: 0.85);

    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

Future<void> showShelfSortSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => const _ShelfSortSheet(),
  );
}

class _ShelfSortSheet extends ConsumerWidget {
  const _ShelfSortSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(shelfDisplayPrefsProvider).sort;
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
                        ref
                            .read(shelfDisplayPrefsProvider.notifier)
                            .setSort(mode);
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
