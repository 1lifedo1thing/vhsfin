import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/state/art_onboarding.dart';
import 'package:vhsfin/features/living_room/widgets/deck_panel.dart';

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
          type: MaterialType.transparency,
          child: DeckPanel(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DeckDisplay(
                  text: _finished ? 'SHELVES STOCKED' : 'GRABBING VHS ART',
                ),
                const SizedBox(height: 16),
                Text('VHSFin', style: vhsBrandStyle(size: 28)),
                const SizedBox(height: 10),
                Text(
                  _finished
                      ? 'Found VHS sleeves for ${progress.foundCount} of '
                            '${progress.total} titles.'
                      : 'Finding VHS sleeves for your titles.',
                  style: TextStyle(
                    color: VhsColors.ink.withValues(alpha: 0.75),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                // A tape-counter style meter set into the panel.
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: const Color(0xFF050607),
                    border: Border.all(),
                    boxShadow: const [
                      BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _finished ? 1 : progress.fraction,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF0C1415),
                      color: VhsColors.accent,
                    ),
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
                  DeckHardKey(
                    label: 'CONTINUE',
                    tone: DeckKeyTone.record,
                    onPressed: onDone,
                  )
                else
                  DeckHardKey(
                    label: 'CONTINUE IN BACKGROUND',
                    onPressed: onDone,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
