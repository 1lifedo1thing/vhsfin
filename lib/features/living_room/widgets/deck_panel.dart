import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/haptics.dart';
import 'package:vhsfin/constants/theme.dart';

/// Parts of a VCR front panel, used to build sheets and dialogs that feel like
/// the same piece of equipment as the TV: brushed plastic with corner screws,
/// a glowing display window, silkscreened labels, LED bays, slide switches,
/// and hardware keys.

/// Opens [builder]'s content as a deck panel rising from the bottom of the
/// screen (Escape and a tap outside close it).
Future<T?> showDeckPanelSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = 460,
  bool scrollable = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      final bottom = MediaQuery.paddingOf(context).bottom;
      final body = builder(context);
      return DismissOnEscape(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: MediaQuery.sizeOf(context).height * 0.9,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: DeckPanel(
                  padding: EdgeInsets.zero,
                  child: scrollable
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                          child: body,
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                          child: body,
                        ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Brushed charcoal fascia with a lit top edge and four screws.
class DeckPanel extends StatelessWidget {
  const DeckPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 20, 18, 18),
    this.radius = 14,
    this.screws = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Corner screws; off for moulded shapes like the remote.
  final bool screws;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        border: Border.all(),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: CustomPaint(
          painter: const _BrushedPlasticPainter(),
          child: Stack(
            children: [
              Padding(padding: padding, child: child),
              if (screws)
                for (final corner in const [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft,
                  Alignment.bottomRight,
                ])
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: corner,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: _Screw(),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrushedPlasticPainter extends CustomPainter {
  const _BrushedPlasticPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2D31), Color(0xFF1B1D20), Color(0xFF141618)],
          stops: [0, 0.38, 1],
        ).createShader(rect),
    );
    // Fine horizontal brushing.
    final grain = Paint()..color = const Color(0x06FFFFFF);
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), grain);
    }
    // Lit top edge, dark bottom lip.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 1),
      Paint()..color = const Color(0x26FFFFFF),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - 2, size.width, 2),
      Paint()..color = const Color(0x88000000),
    );
  }

  @override
  bool shouldRepaint(_BrushedPlasticPainter oldDelegate) => false;
}

class _Screw extends StatelessWidget {
  const _Screw();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size.square(10), painter: _ScrewPainter());
}

class _ScrewPainter extends CustomPainter {
  const _ScrewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c.translate(0, 0.6),
      r,
      Paint()..color = const Color(0x22FFFFFF),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFF9AA0A6), Color(0xFF3E4246)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final slot = Paint()
      ..color = const Color(0xFF1D1F22)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.6);
    canvas.drawLine(Offset(-r * 0.6, 0), Offset(r * 0.6, 0), slot);
    canvas.drawLine(Offset(0, -r * 0.6), Offset(0, r * 0.6), slot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScrewPainter oldDelegate) => false;
}

/// Glowing fluorescent display window — the panel's title.
class DeckDisplay extends StatelessWidget {
  const DeckDisplay({super.key, required this.text, this.detail});

  final String text;

  /// Dimmer readout on the right, like a channel or counter.
  final String? detail;

  static TextStyle style(double size, {double alpha = 1}) => TextStyle(
    fontFamily: 'VT323',
    fontSize: size,
    height: 1,
    letterSpacing: size * 0.1,
    color: VhsColors.accent.withValues(alpha: alpha),
    shadows: [
      Shadow(
        color: VhsColors.accent.withValues(alpha: 0.6 * alpha),
        blurRadius: 8,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF030607), Color(0xFF081012)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1)),
        ],
        border: Border.all(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style(28),
            ),
          ),
          if (detail != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style(18, alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Display window plus a slim close button: the header of a deck sheet.
class DeckPanelHeader extends StatelessWidget {
  const DeckPanelHeader({
    super.key,
    required this.title,
    this.detail,
    this.onClose,
  });

  final String title;
  final String? detail;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DeckDisplay(text: title, detail: detail),
        ),
        if (onClose != null) ...[
          const SizedBox(width: 6),
          DeckCloseButton(onPressed: onClose!),
        ],
      ],
    );
  }
}

/// A slim title row — silkscreened name, optional actions, and a close X.
/// For sheets where the content, not the chrome, should lead.
class DeckSheetHeader extends StatelessWidget {
  const DeckSheetHeader({
    super.key,
    required this.title,
    required this.onClose,
    this.detail,
    this.actions = const [],
  });

  final String title;
  final String? detail;
  final List<Widget> actions;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const DeckLed(on: true, color: VhsColors.record),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFC9D1D4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.6,
            ),
          ),
        ),
        if (detail != null) ...[
          const SizedBox(width: 10),
          Text(
            detail!,
            style: const TextStyle(
              color: VhsColors.inkFaint,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
        ],
        const Spacer(),
        ...actions,
        DeckCloseButton(onPressed: onClose),
      ],
    );
  }
}

/// The one close control every sheet uses: a small, quiet X.
class DeckCloseButton extends StatelessWidget {
  const DeckCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        DeckHaptics.tap();
        onPressed();
      },
      tooltip: 'Close',
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      color: VhsColors.inkMuted,
      icon: const Icon(Icons.close_rounded),
    );
  }
}

/// Immediate press feedback: [builder] sees the press the moment the pointer
/// lands (tap recognizers wait up to 100ms inside scrollables), and it stays
/// visible for at least [minimum] so quick taps still read.
class DeckPressable extends StatefulWidget {
  const DeckPressable({
    super.key,
    required this.onTap,
    required this.builder,
    this.haptic = DeckHaptics.tap,
    this.minimum = const Duration(milliseconds: 90),
    this.onPressStart,
    this.onPressEnd,
  });

  /// Called the instant the pointer lands / lifts — for keys that act while
  /// held (REW, FF). [onPressEnd] also runs if the press is cancelled.
  final VoidCallback? onPressStart;
  final VoidCallback? onPressEnd;

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool pressed) builder;

  /// Felt the moment the pointer lands (see [DeckHaptics]); null for none.
  final VoidCallback? haptic;
  final Duration minimum;

  @override
  State<DeckPressable> createState() => _DeckPressableState();
}

class _DeckPressableState extends State<DeckPressable> {
  var _pressed = false;
  DateTime? _downAt;
  Timer? _release;

  void _down(PointerDownEvent _) {
    if (widget.onTap == null) return;
    _release?.cancel();
    _downAt = DateTime.now();
    widget.haptic?.call();
    widget.onPressStart?.call();
    setState(() => _pressed = true);
  }

  void _up(PointerEvent _) {
    if (!_pressed) return;
    widget.onPressEnd?.call();
    final held = DateTime.now().difference(_downAt ?? DateTime.now());
    final wait = widget.minimum - held;
    _release?.cancel();
    if (wait <= Duration.zero) {
      setState(() => _pressed = false);
      return;
    }
    _release = Timer(wait, () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  void dispose() {
    _release?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: _up,
      onPointerCancel: _up,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _pressed),
      ),
    );
  }
}

/// Silkscreened section label with a fading rule.
class DeckLabel extends StatelessWidget {
  const DeckLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 16, 0, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFC9D1D4),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0x55C9D1D4), Color(0x00C9D1D4)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicator LED; cyan and glowing when [on].
class DeckLed extends StatelessWidget {
  const DeckLed({super.key, required this.on, this.color = VhsColors.accent});

  final bool on;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? color : const Color(0xFF1F2A2B),
        border: Border.all(width: 0.5),
        boxShadow: on
            ? [
                BoxShadow(color: color, blurRadius: 6),
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 12),
              ]
            : null,
      ),
    );
  }
}

/// A recessed bay with an LED above it — a selectable input on the deck.
class DeckBay extends StatelessWidget {
  const DeckBay({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: DeckPressable(
        onTap: onTap,
        builder: (context, pressed) => Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: pressed
                  ? const [Color(0xFF050607), Color(0xFF0D0E10)]
                  : const [Color(0xFF0B0C0E), Color(0xFF16181B)],
            ),
            border: Border.all(),
            boxShadow: const [
              BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DeckLed(on: selected),
              const SizedBox(height: 5),
              child,
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? VhsColors.accent : const Color(0xFFAEB7BB),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-position slide switch, like a deck's SP/EP selector.
class DeckSlideSwitch extends StatelessWidget {
  const DeckSlideSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const _trackW = 54.0;
  static const _thumbW = 24.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      // The option row around it already gives the toggle its feel.
      onTap: () => onChanged(!value),
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() > 50 && (v > 0) != value) {
          DeckHaptics.toggle();
          onChanged(v > 0);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _trackW,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF050606), Color(0xFF121416)],
              ),
              border: Border.all(),
              boxShadow: const [
                BoxShadow(color: Color(0x14FFFFFF), offset: Offset(0, 1)),
              ],
            ),
            child: AnimatedAlign(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: _thumbW,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  // Ridged metal thumb.
                  gradient: const LinearGradient(
                    end: Alignment(-0.83, 0),
                    colors: [Color(0xFF6E7377), Color(0xFFA2A8AC)],
                    tileMode: TileMode.mirror,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xCC000000),
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: _trackW,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // Printed on the switch body; the toggled state is announced,
              // so these grow only a little with large text.
              children: [
                _mark(context, 'OFF', !value),
                _mark(context, 'ON', value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mark(BuildContext context, String text, bool active) => Text(
    text,
    textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2),
    style: TextStyle(
      color: active
          ? (text == 'ON' ? VhsColors.accent : const Color(0xFFC9D1D4))
          : const Color(0xFF5E676C),
      fontSize: 7.5,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );
}

/// An option with its explanation and a slide switch.
class DeckOptionRow extends StatelessWidget {
  const DeckOptionRow({
    super.key,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      hint: subtitle,
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: DeckPressable(
        onTap: () => onChanged(!value),
        haptic: DeckHaptics.toggle,
        builder: (context, pressed) => Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: pressed ? const Color(0x0DFFFFFF) : const Color(0x05FFFFFF),
            border: Border.all(color: const Color(0x0DFFFFFF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFD9E0E2),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: VhsColors.inkMuted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DeckSlideSwitch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// A hardware key set into the panel: it sits in a dark socket with its
/// side showing below the face, and sinks when pressed.
class DeckHardKey extends StatelessWidget {
  const DeckHardKey({
    super.key,
    required this.label,
    required this.onPressed,
    this.sublabel,
    this.semanticLabel,
    this.tone = DeckKeyTone.grey,
  });

  final String label;
  final String? sublabel;
  final String? semanticLabel;

  /// Null disables the key (shown dimmed, doesn't press).
  final VoidCallback? onPressed;
  final DeckKeyTone tone;

  /// How far the face stands above its socket; a press takes all but 1px.
  static const _travel = 4.0;

  @override
  Widget build(BuildContext context) {
    final t = _KeyTone.of(tone);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: DeckPressable(
        onTap: onPressed,
        haptic: DeckHaptics.key,
        builder: (context, down) {
          final side = down ? 1.0 : _travel;
          final key = Container(
            // Socket: the hole in the panel the key sits in.
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF020303), Color(0xFF0B0C0D)],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x1AFFFFFF), offset: Offset(0, 1)),
              ],
            ),
            child: Padding(
              // Keep the footprint fixed while the key sinks.
              padding: EdgeInsets.only(top: _travel - side),
              child: DecoratedBox(
                // The key's side, visible below the face.
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: t.side,
                  boxShadow: down
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 3,
                            offset: Offset(0, 2),
                          ),
                        ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: side),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 38),
                    padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        // A lit lip along the top edge, then the face.
                        colors: down
                            ? [
                                t.faceTop,
                                t.faceTop,
                                t.pressedTop,
                                t.pressedBottom,
                              ]
                            : [t.lip, t.lip, t.faceTop, t.faceBottom],
                        stops: const [0, 0.04, 0.1, 1],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.ink,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            shadows: [
                              Shadow(
                                color: t.engrave,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        if (sublabel != null)
                          Text(
                            sublabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.ink.withValues(alpha: 0.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          return onPressed == null ? Opacity(opacity: 0.55, child: key) : key;
        },
      ),
    );
  }
}

enum DeckKeyTone { grey, record }

class _KeyTone {
  const _KeyTone({
    required this.lip,
    required this.faceTop,
    required this.faceBottom,
    required this.pressedTop,
    required this.pressedBottom,
    required this.side,
    required this.ink,
    required this.engrave,
  });

  final Color lip;
  final Color faceTop;
  final Color faceBottom;
  final Color pressedTop;
  final Color pressedBottom;
  final Color side;
  final Color ink;
  final Color engrave;

  static _KeyTone of(DeckKeyTone tone) => switch (tone) {
    DeckKeyTone.grey => const _KeyTone(
      lip: Color(0xFFF2F4F5),
      faceTop: Color(0xFFD2D6D9),
      faceBottom: Color(0xFFA3A9AD),
      pressedTop: Color(0xFFB4B9BD),
      pressedBottom: Color(0xFF93999D),
      side: Color(0xFF52575B),
      ink: Color(0xFF1D2023),
      engrave: Color(0x80FFFFFF),
    ),
    DeckKeyTone.record => const _KeyTone(
      lip: Color(0xFFFFA59C),
      faceTop: Color(0xFFEB6257),
      faceBottom: Color(0xFFC0372D),
      pressedTop: Color(0xFFCB4439),
      pressedBottom: Color(0xFFA42C23),
      side: Color(0xFF6E1B15),
      ink: Colors.white,
      engrave: Color(0x66000000),
    ),
  };
}
