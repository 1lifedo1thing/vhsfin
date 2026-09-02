import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/living_room/presentation/bookshelf_view.dart';
import 'package:vhsfin/features/living_room/presentation/vcr_box.dart';
import 'package:vhsfin/features/living_room/presentation/vhs_remote.dart';

class LivingRoomPage extends ConsumerWidget {
  const LivingRoomPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Scaffold(
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

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(pad, 20, pad, 12),
                      child: const _EntertainmentCenter(),
                    ),
                  ),
                  _BottomBar(
                    connected: session != null,
                    userName: session?.userName,
                    onRemote: () => showVhsRemote(context),
                    onCollection: () => context.push('/libraries'),
                    onConnect: () => context.push('/connect'),
                    onSignOut: () =>
                        ref.read(sessionProvider.notifier).signOut(),
                  ),
                ],
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top surface — VCR rests here.
          VcrBox(),
          SizedBox(height: 14),
          // Shelf cavity under the VCR.
          BookshelfView(embedded: true),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.connected,
    required this.onRemote,
    required this.onCollection,
    required this.onConnect,
    required this.onSignOut,
    this.userName,
  });

  final bool connected;
  final String? userName;
  final VoidCallback onRemote;
  final VoidCallback onCollection;
  final VoidCallback onConnect;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRemote,
              icon: const Icon(Icons.settings_remote_rounded),
              label: const Text('REMOTE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A2A28),
                foregroundColor: VhsColors.brand,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onCollection,
                child: Text(
                  'COLLECTION',
                  style: TextStyle(
                    color: VhsColors.phosphor.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text(
                '·',
                style: TextStyle(
                  color: VhsColors.brand.withValues(alpha: 0.35),
                ),
              ),
              TextButton(
                onPressed: connected ? onSignOut : onConnect,
                child: Text(
                  connected
                      ? 'SIGN OUT${userName != null ? ' ($userName)' : ''}'
                      : 'CONNECT',
                  style: TextStyle(
                    color: VhsColors.brand.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
