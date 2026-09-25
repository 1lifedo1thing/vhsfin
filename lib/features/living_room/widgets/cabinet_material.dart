import 'package:flutter/material.dart';
import 'package:vhsfin/features/living_room/model/cabinet_style.dart';

/// Makes the chosen [CabinetStyle] available to every panel and ledge below.
class CabinetScope extends InheritedWidget {
  const CabinetScope({super.key, required this.style, required super.child});

  final CabinetStyle style;

  static CabinetStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CabinetScope>()?.style ??
      CabinetStyle.flat;

  @override
  bool updateShouldNotify(CabinetScope oldWidget) => style != oldWidget.style;
}

/// A cabinet face or a recessed bay in the current [CabinetStyle].
///
/// [grain] picks which part of the walnut tile shows, so neighbouring pieces
/// don't repeat the same strip of wood. The tile is seamless and drawn at a
/// fixed physical scale: it is cropped and repeated, never stretched.
class CabinetPanel extends StatelessWidget {
  const CabinetPanel({
    super.key,
    required this.child,
    this.recessed = false,
    this.radius = 3,
    this.padding = EdgeInsets.zero,
    this.grain = Alignment.topLeft,
  });

  final Widget child;
  final bool recessed;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Alignment grain;

  @override
  Widget build(BuildContext context) {
    final walnut = CabinetScope.of(context) == CabinetStyle.walnut;
    final shape = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        color: walnut
            ? const Color(0xFF3D281B)
            : recessed
            ? const Color(0xFF050607)
            : const Color(0xFF121518),
        image: walnut
            ? DecorationImage(
                image: const ExactAssetImage(
                  'assets/branding/walnut.jpg',
                  scale: 2,
                ),
                fit: BoxFit.none,
                repeat: ImageRepeat.repeat,
                alignment: grain,
                filterQuality: FilterQuality.medium,
              )
            : null,
        boxShadow: recessed
            ? null
            : const [
                BoxShadow(
                  color: Color(0xAA000000),
                  blurRadius: 4,
                  offset: Offset(0, 3),
                ),
              ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: switch ((walnut, recessed)) {
              (true, true) => const [
                Color(0xD9000000),
                Color(0x70000000),
                Color(0xB0000000),
              ],
              (true, false) => const [
                Color(0x407E5C38),
                Color(0x08000000),
                Color(0x70000000),
              ],
              // Flat bay: shadow under the shelf above, a hint of floor bounce.
              (false, true) => const [
                Color(0xFF000000),
                Color(0x00000000),
                Color(0x14FFFFFF),
              ],
              (false, false) => const [
                Color(0x14FFFFFF),
                Color(0x00FFFFFF),
                Color(0x66000000),
              ],
            },
            stops: const [0, 0.22, 1],
          ),
          border: Border.all(
            color: recessed
                ? const Color(0xB0000000)
                : walnut
                ? const Color(0x407C6248)
                : const Color(0x14FFFFFF),
          ),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// A rounded solid front edge with a lit upper bevel.
class CabinetLedge extends StatelessWidget {
  const CabinetLedge({
    super.key,
    this.height = 18,
    this.grain = const Alignment(0.3, -0.2),
  });

  final double height;
  final Alignment grain;

  @override
  Widget build(BuildContext context) {
    final walnut = CabinetScope.of(context) == CabinetStyle.walnut;
    return CabinetPanel(
      radius: 3,
      grain: grain,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: walnut
                  ? const [
                      Color(0x50D7AD78),
                      Color(0x007D522E),
                      Color(0xCC160B05),
                    ]
                  : const [
                      Color(0x1FFFFFFF),
                      Color(0x00FFFFFF),
                      Color(0xCC000000),
                    ],
              stops: const [0, 0.3, 1],
            ),
            border: Border(
              top: BorderSide(
                color: walnut
                    ? const Color(0xA8D3A16C)
                    : const Color(0x33FFFFFF),
              ),
              bottom: const BorderSide(color: Color(0xD0000000)),
            ),
          ),
        ),
      ),
    );
  }
}
