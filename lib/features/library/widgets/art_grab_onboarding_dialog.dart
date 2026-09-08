import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';

/// First-time VHS art grab tour — props only; page owns Riverpod.
class ArtGrabOnboardingDialog extends StatelessWidget {
  const ArtGrabOnboardingDialog({
    super.key,
    required this.progress,
    required this.onDone,
  });

  final ArtWarmProgress progress;
  final VoidCallback onDone;

  bool get _finished => progress.phase == ArtWarmPhase.done;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: const Color(0xFF1A100C),
          borderRadius: BorderRadius.circular(14),
          elevation: 24,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                Text(
                  _finished ? 'SHELVES STOCKED' : 'GRABBING VHS ART',
                  style: TextStyle(
                    color: VhsColors.phosphor.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'VHSFin',
                  style: vhsBrandStyle(size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  _finished
                      ? 'Found VHS posters for ${progress.foundCount} of '
                          '${progress.total} titles. Spines will use sleeve '
                          'art when available.'
                      : 'Looking up VHS tapes and posters for your shelves. '
                          'Titles already in the cache skip the network — '
                          'only new ones take longer.',
                  style: TextStyle(
                    color: VhsColors.brand.withValues(alpha: 0.75),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _finished ? 1 : progress.fraction,
                    minHeight: 10,
                    backgroundColor: Colors.black.withValues(alpha: 0.45),
                    color: VhsColors.phosphor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _finished
                      ? '${progress.foundCount} posters ready'
                      : progress.total == 0
                          ? 'Starting…'
                          : '${progress.completed} / ${progress.total}'
                              '${progress.foundCount > 0 ? ' · ${progress.foundCount} hits' : ''}',
                  style: TextStyle(
                    color: VhsColors.brand.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                if (_finished) ...[
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: onDone,
                    child: const Text('CONTINUE'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
