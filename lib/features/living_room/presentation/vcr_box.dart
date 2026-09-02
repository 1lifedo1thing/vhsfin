import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/living_room/model/vcr_state.dart';
import 'package:vhsfin/features/living_room/presentation/vcr_crt_screen.dart';

/// Living-room VCR / TV combo that sits on the wooden console.
class VcrBox extends ConsumerWidget {
  const VcrBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(vcrDeckProvider);
    final ledOn = deck.isPowered;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VhsColors.vcrFace,
            VhsColors.vcrBody,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          if (ledOn)
            BoxShadow(
              color: VhsColors.phosphor.withValues(alpha: 0.14),
              blurRadius: 22,
              spreadRadius: 1,
            ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'VHSFIN',
                style: vhsBrandStyle(size: 14).copyWith(letterSpacing: 3),
              ),
              const Spacer(),
              _Led(on: ledOn),
              const SizedBox(width: 8),
              Text(
                ledOn ? 'PLAY' : 'STANDBY',
                style: TextStyle(
                  color: ledOn ? VhsColors.phosphor : VhsColors.phosphorDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VhsColors.vcrBezel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            child: VcrCrtScreen(
              power: deck.power,
              style: deck.style,
              tape: deck.loadedTape,
            ),
          ),
          if (deck.loadedTape != null) ...[
            const SizedBox(height: 10),
            Text(
              deck.loadedTape!.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: VhsColors.brand,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Led extends StatelessWidget {
  const _Led({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? VhsColors.ledOn : VhsColors.ledOff,
        boxShadow: on
            ? [
                BoxShadow(
                  color: VhsColors.ledOn.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }
}
