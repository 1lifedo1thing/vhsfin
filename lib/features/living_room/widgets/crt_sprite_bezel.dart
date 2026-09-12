import 'package:flutter/material.dart';
import 'package:vhsfin/features/living_room/model/crt_sprite_layout.dart';
import 'package:vhsfin/features/living_room/model/crt_tv_skin.dart';

/// Draws one CRT cabinet (atlas crop or standalone asset) and fills the parent.
class CrtSpriteBezel extends StatelessWidget {
  const CrtSpriteBezel({super.key, required this.skin});

  final CrtTvSkin skin;

  @override
  Widget build(BuildContext context) {
    final layout = CrtSpriteLayout.of(skin);
    final src = layout.sourceRect;
    final assetSize = layout.assetSize;
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: src.width,
        height: src.height,
        child: ClipRect(
          child: OverflowBox(
            minWidth: assetSize.width,
            maxWidth: assetSize.width,
            minHeight: assetSize.height,
            maxHeight: assetSize.height,
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(-src.left, -src.top),
              child: Image.asset(
                layout.asset,
                width: assetSize.width,
                height: assetSize.height,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
