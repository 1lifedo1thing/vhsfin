import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/tape_shelf.dart';
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
              final content = <Widget>[
                _HeroHeader(
                  connected: session != null,
                  userName: session?.userName,
                  onConnect: () => context.push('/connect'),
                  onSignOut: () =>
                      ref.read(sessionProvider.notifier).signOut(),
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
                TapeShelf(
                  onSelect: (tape) {
                    ref.read(vcrDeckProvider.notifier).insertTape(tape);
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  session == null
                      ? 'Demo tapes for now. Connect Jellyfin when you are ready.'
                      : 'Tapes from ${session.normalizedServerUrl}',
                  style: TextStyle(
                    color: VhsColors.brand.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
              ];

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? constraints.maxWidth * 0.14 : 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: content,
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
    this.userName,
  });

  final bool connected;
  final String? userName;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;

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
              ? 'Hi ${userName ?? 'friend'} — pick a tape and press play.'
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
