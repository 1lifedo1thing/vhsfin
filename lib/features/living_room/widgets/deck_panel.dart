import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    isDismissible: true,
    enableDrag: true,
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
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        border: Border.all(color: Colors.black),
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

  static TextStyle style(double size, {double alpha = 1}) => GoogleFonts.vt323(
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
        border: Border.all(color: Colors.black),
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

/// Display window plus a close key: the header of every deck sheet.
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
          const SizedBox(width: 10),
          DeckHardKey(
            label: '✕',
            semanticLabel: 'Close',
            compact: true,
            onPressed: onClose!,
          ),
        ],
      ],
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
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFC9D1D4),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.6,
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
        border: Border.all(color: Colors.black, width: 0.5),
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 8, 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B0C0E), Color(0xFF16181B)],
            ),
            border: Border.all(color: Colors.black),
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
      onTap: () => onChanged(!value),
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() > 50) onChanged(v > 0);
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
              border: Border.all(color: Colors.black),
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
                    begin: Alignment(-1, 0),
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
              children: [_mark('OFF', !value), _mark('ON', value)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mark(String text, bool active) => Text(
    text,
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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            color: const Color(0x05FFFFFF),
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

/// A light-grey hardware key that travels when pressed.
class DeckHardKey extends StatefulWidget {
  const DeckHardKey({
    super.key,
    required this.label,
    required this.onPressed,
    this.sublabel,
    this.semanticLabel,
    this.compact = false,
    this.tone = DeckKeyTone.grey,
  });

  final String label;
  final String? sublabel;
  final String? semanticLabel;
  final VoidCallback onPressed;

  /// Square key for icons (close) instead of a labelled key.
  final bool compact;
  final DeckKeyTone tone;

  @override
  State<DeckHardKey> createState() => _DeckHardKeyState();
}

enum DeckKeyTone { grey, record }

class _DeckHardKeyState extends State<DeckHardKey> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.tone == DeckKeyTone.record;
    final top = record ? const Color(0xFFE65A4F) : const Color(0xFFC9CED1);
    final bottom = record ? const Color(0xFFB53228) : const Color(0xFF9AA0A4);
    final skirt = record ? const Color(0xFF6B1B15) : const Color(0xFF4A4F53);
    final ink = record ? Colors.white : const Color(0xFF1D2023);
    final travel = _down ? 2.0 : 0.0;

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            transform: Matrix4.translationValues(0, travel, 0),
            constraints: BoxConstraints(
              minWidth: widget.compact ? 40 : 0,
              minHeight: widget.compact ? 40 : 44,
            ),
            padding: widget.compact
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(8, 9, 8, 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, bottom],
              ),
              border: const Border(top: BorderSide(color: Color(0x99FFFFFF))),
              boxShadow: [
                BoxShadow(color: skirt, offset: Offset(0, 3 - travel)),
                BoxShadow(
                  color: const Color(0xAA000000),
                  blurRadius: 8 - travel * 2,
                  offset: Offset(0, 5 - travel),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: widget.compact ? 15 : 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: widget.compact ? 0 : 1.6,
                  ),
                ),
                if (widget.sublabel != null)
                  Text(
                    widget.sublabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.72),
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
    );
  }
}
