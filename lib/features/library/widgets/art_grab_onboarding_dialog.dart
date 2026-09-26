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
          color: VhsColors.surface,
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
                colors: [VhsColors.surfaceRaised, VhsColors.surface],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _finished ? 'SHELVES STOCKED' : 'GRABBING VHS ART',
                  style: TextStyle(
                    color: VhsColors.accent.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text('VHSFin', style: vhsBrandStyle(size: 28)),
                const SizedBox(height: 10),
                Text(
                  _finished
                      ? 'Found original VHS sleeves for '
                            '${progress.foundCount} of ${progress.total} titles. '
                            'The rest get a printed spine.'
                      : 'Looking for the original VHS sleeve of each title. '
                            'This happens once; you can keep browsing while '
                            'it finishes.',
                  style: TextStyle(
                    color: VhsColors.ink.withValues(alpha: 0.75),
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
                    color: VhsColors.accent,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _finished
                      ? '${progress.foundCount} sleeves found'
                      : progress.total == 0
                      ? 'Starting…'
                      : '${progress.completed} / ${progress.total}'
                            '${progress.foundCount > 0 ? ' · ${progress.foundCount} found' : ''}',
                  style: TextStyle(
                    color: VhsColors.ink.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 18),
                if (_finished)
                  ElevatedButton(
                    onPressed: onDone,
                    child: const Text('CONTINUE'),
                  )
                else
                  TextButton(
                    onPressed: onDone,
                    child: const Text('CONTINUE IN BACKGROUND'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
