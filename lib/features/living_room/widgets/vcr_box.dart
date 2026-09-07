import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/vcr_deck_notifier.dart';
import 'package:vhsfin/features/living_room/widgets/vcr_crt_screen.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';
import 'package:vhsfin/features/playback/state/deck_player.dart';

/// Compact Zenith-style all-in-one TV/VCR — CRT hood, cassette door, deck keys.
class VcrBox extends StatelessWidget {
  const VcrBox({
    super.key,
    required this.deck,
    required this.player,
    required this.surfaceEpoch,
    required this.slotKey,
    required this.flyingTapeId,
    required this.slotArt,
    required this.onRew,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFf,
    required this.onFfEnd,
    required this.onEject,
    required this.onFull,
    this.rewinding = false,
  });

  final VcrDeckState deck;
  final DeckPlayerController player;
  final int surfaceEpoch;
  final GlobalKey slotKey;
  final String? flyingTapeId;
  final VhsSpineArt? slotArt;
  final VoidCallback onRew;
  final VoidCallback onRewEnd;
  final VoidCallback onPlay;
  final VoidCallback onFf;
  final VoidCallback onFfEnd;
  final VoidCallback onEject;
  final VoidCallback onFull;
  final bool rewinding;

  @override
  Widget build(BuildContext context) {
    final ledOn = deck.isPowered;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A4A4E),
            Color(0xFF2E2E32),
            Color(0xFF1A1A1E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          if (ledOn)
            BoxShadow(
              color: VhsColors.phosphor.withValues(alpha: 0.12),
              blurRadius: 18,
            ),
        ],
        border: Border.all(color: const Color(0xFF5A5A60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand badge row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Row(
              children: [
                Text(
                  'VHSFIN',
                  style: vhsBrandStyle(size: 12).copyWith(letterSpacing: 3),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: VhsColors.brand.withValues(alpha: 0.25),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'COLOR TV · VCR',
                    style: TextStyle(
                      color: VhsColors.brand.withValues(alpha: 0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                _Led(on: ledOn),
                const SizedBox(width: 6),
                Text(
                  ledOn ? 'PLAY' : 'OFF',
                  style: TextStyle(
                    color: ledOn ? VhsColors.phosphor : VhsColors.phosphorDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // CRT with deep hood / bezel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0E0E10),
                    Color(0xFF18181C),
                    Color(0xFF0A0A0C),
                  ],
                ),
                border: Border.all(color: const Color(0xFF2A2A2E), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: VcrCrtScreen(
                power: deck.power,
                style: deck.style,
                tape: deck.loadedTape,
                player: player,
                surfaceEpoch: surfaceEpoch,
                resumeAt: deck.resumeAt,
                rewinding: rewinding,
              ),
            ),
          ),
          // Chrome strip
          Container(
            margin: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6A6A70),
                  Color(0xFFC8C8D0),
                  Color(0xFF7A7A80),
                  Color(0xFFB0B0B8),
                  Color(0xFF5A5A60),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: KeyedSubtree(
              key: slotKey,
              child: _CassetteSlot(
                tape: deck.loadedTape,
                art: slotArt,
                flyingTapeId: flyingTapeId,
                inserting: deck.power == VcrPower.inserting,
                ejecting: deck.power == VcrPower.ejecting,
                loaded: deck.loadedTape != null &&
                    (deck.power == VcrPower.playing ||
                        deck.power == VcrPower.inserting ||
                        deck.power == VcrPower.ejecting),
              ),
            ),
          ),
          // Vent / speaker grille suggestion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(
                18,
                (i) => Expanded(
                  child: Container(
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: i.isEven
                          ? const Color(0xFF121214)
                          : const Color(0xFF2A2A2E),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: _DeckButtons(
              enabled: deck.isPowered,
              rewinding: rewinding,
              onRew: onRew,
              onRewEnd: onRewEnd,
              onPlay: onPlay,
              onFf: onFf,
              onFfEnd: onFfEnd,
              onEject: onEject,
              onFull: onFull,
            ),
          ),
        ],
      ),
    );
  }
}

class _CassetteSlot extends StatelessWidget {
  const _CassetteSlot({
    required this.inserting,
    required this.ejecting,
    required this.loaded,
    required this.flyingTapeId,
    this.tape,
    this.art,
  });

  final Tape? tape;
  final VhsSpineArt? art;
  final String? flyingTapeId;
  final bool inserting;
  final bool ejecting;
  final bool loaded;

  @override
  Widget build(BuildContext context) {
    // Overlay owns the cassette while the tape is mid-flight.
    final hideForFlight =
        tape != null && flyingTapeId != null && flyingTapeId == tape!.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Door / flap above the mouth
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A3A40), Color(0xFF222226)],
            ),
            border: Border.all(color: Colors.black.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF111114),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
        Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(3)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF050506), Color(0xFF141418)],
            ),
            border: Border.all(color: Colors.black),
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 4,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
              if ((loaded || inserting || ejecting) && !hideForFlight)
                Align(
                  // Flight overlay owns insert/eject motion; bay only holds.
                  alignment: Alignment.center,
                  child: _SlotCassette(
                    title: tape?.title,
                    art: art,
                  ),
                )
              else if (!loaded && !inserting && !ejecting)
                const Center(
                  child: Text(
                    'VHS',
                    style: TextStyle(
                      color: Color(0xFF333338),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal cassette body in the bay — spine art rotated to read along the slot.
class _SlotCassette extends StatelessWidget {
  const _SlotCassette({this.title, this.art});

  final String? title;
  final VhsSpineArt? art;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: VhsColors.tapeShell,
        border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: art != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Force vertical spine canvas to (slotH × slotW), then rotate so
                // it exactly fills the bay — RotatedBox alone sizes to the crop
                // strip and chops the title off.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;
                    return Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SizedBox(
                          width: h,
                          height: w,
                          child: VhsSleeveCrop(
                            url: art!.imageUrl,
                            widthFraction: art!.centerWidthFraction,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        bottom: BorderSide(
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                (title ?? 'TAPE').toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF2A1810),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
    );
  }
}

class _DeckButtons extends StatelessWidget {
  const _DeckButtons({
    required this.enabled,
    required this.rewinding,
    required this.onRew,
    required this.onRewEnd,
    required this.onPlay,
    required this.onFf,
    required this.onFfEnd,
    required this.onEject,
    required this.onFull,
  });

  final bool enabled;
  final bool rewinding;
  final VoidCallback onRew;
  final VoidCallback onRewEnd;
  final VoidCallback onPlay;
  final VoidCallback onFf;
  final VoidCallback onFfEnd;
  final VoidCallback onEject;
  final VoidCallback onFull;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DeckKey(
          icon: Icons.fast_rewind_rounded,
          label: 'REW',
          enabled: enabled,
          emphasized: rewinding,
          onTapDown: (_) => onRew(),
          onTapUp: (_) => onRewEnd(),
          onTapCancel: onRewEnd,
        ),
        _DeckKey(
          icon: Icons.play_arrow_rounded,
          label: 'PLAY',
          enabled: enabled,
          emphasized: true,
          onTap: onPlay,
        ),
        _DeckKey(
          icon: Icons.fast_forward_rounded,
          label: 'FF',
          enabled: enabled,
          onTapDown: (_) => onFf(),
          onTapUp: (_) => onFfEnd(),
          onTapCancel: onFfEnd,
        ),
        _DeckKey(
          icon: Icons.eject_rounded,
          label: 'EJECT',
          enabled: enabled,
          onTap: onEject,
        ),
        _DeckKey(
          icon: Icons.fullscreen_rounded,
          label: 'FULL',
          enabled: enabled,
          onTap: onFull,
        ),
      ],
    );
  }
}

class _DeckKey extends StatelessWidget {
  const _DeckKey({
    required this.icon,
    required this.label,
    required this.enabled,
    this.emphasized = false,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool emphasized;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final VoidCallback? onTapCancel;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? VhsColors.brand.withValues(alpha: 0.22)
        : emphasized
            ? VhsColors.phosphor
            : VhsColors.brand.withValues(alpha: 0.8);

    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        onTapDown: enabled ? onTapDown : null,
        onTapUp: enabled ? onTapUp : null,
        onTapCancel: enabled ? onTapCancel : null,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2A2A2E), Color(0xFF101012)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
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
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? VhsColors.ledOn : VhsColors.ledOff,
        boxShadow: on
            ? [
                BoxShadow(
                  color: VhsColors.ledOn.withValues(alpha: 0.7),
                  blurRadius: 7,
                ),
              ]
            : null,
      ),
    );
  }
}
