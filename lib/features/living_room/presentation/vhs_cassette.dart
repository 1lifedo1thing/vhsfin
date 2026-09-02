import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/model/tape.dart';

class VhsCassette extends StatelessWidget {
  const VhsCassette({
    super.key,
    required this.tape,
    this.selected = false,
    this.onTap,
    this.width = 108,
  });

  final Tape tape;
  final bool selected;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.55;

    return Semantics(
      button: true,
      label: 'Play ${tape.title}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: width,
          height: height,
          transform: Matrix4.translationValues(0, selected ? -10 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.55 : 0.35),
                blurRadius: selected ? 18 : 10,
                offset: Offset(0, selected ? 10 : 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: VhsColors.tapeShell),
                Positioned(
                  left: 8,
                  right: 8,
                  top: 10,
                  bottom: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: VhsColors.tapeLabel,
                      borderRadius: BorderRadius.circular(2),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tape.title.toUpperCase(),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF2A1810),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const Spacer(),
                          if (tape.subtitle != null)
                            Text(
                              tape.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF2A1810)
                                    .withValues(alpha: 0.65),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 22,
                  child: ColoredBox(
                    color: VhsColors.accent.withValues(alpha: 0.9),
                    child: const Center(
                      child: Text(
                        'VHS',
                        style: TextStyle(
                          color: VhsColors.brand,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
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
