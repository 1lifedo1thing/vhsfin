import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/bookshelf_view.dart';
import 'package:vhsfin/features/living_room/presentation/vcr_box.dart';

class LivingRoomPage extends ConsumerWidget {
  const LivingRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.55),
            radius: 1.15,
            colors: [
              VhsColors.woodMid,
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
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? constraints.maxWidth * 0.12 : 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroHeader(
                      connected: session != null,
                      userName: session?.userName,
                      onConnect: () => context.push('/connect'),
                      onSignOut: () =>
                          ref.read(sessionProvider.notifier).signOut(),
                      onShelves: () => context.push('/libraries'),
                    ),
                    const SizedBox(height: 18),
                    VcrBox(
                      onOpenClean: () {
                        final tape = ref.read(vcrDeckProvider).loadedTape;
                        if (tape == null) return;
                        ref
                            .read(vcrDeckProvider.notifier)
                            .setStyle(PlaybackStyle.cleanFullscreen);
                        context.push('/play');
                      },
                    ),
                    const SizedBox(height: 28),
                    const BookshelfView(),
                    const SizedBox(height: 20),
                    Text(
                      session == null
                          ? 'Demo tapes for now. Connect Jellyfin, then pick kids libraries under SHELVES.'
                          : 'Shelves from ${session.normalizedServerUrl}',
                      style: TextStyle(
                        color: VhsColors.brand.withValues(alpha: 0.55),
                        fontSize: 13,
                      ),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.connected,
    required this.onConnect,
    required this.onSignOut,
    required this.onShelves,
    this.userName,
  });

  final bool connected;
  final String? userName;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;
  final VoidCallback onShelves;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text('VHSFIN', style: vhsBrandStyle(size: 44)),
            ),
            TextButton(
              onPressed: onShelves,
              child: const Text(
                'SHELVES',
                style: TextStyle(
                  color: VhsColors.phosphor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            TextButton(
              onPressed: connected ? onSignOut : onConnect,
              child: Text(
                connected ? 'SIGN OUT' : 'CONNECT',
                style: const TextStyle(
                  color: VhsColors.phosphor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          connected
              ? 'Hi ${userName ?? 'friend'} — pull a spine, or open a TV box for episodes.'
              : 'A kids VCR for your Jellyfin library.',
          style: TextStyle(
            color: VhsColors.brand.withValues(alpha: 0.72),
            fontSize: 16,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
