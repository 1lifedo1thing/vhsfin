import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:vhsfin/constants/theme.dart';

/// Fullscreen player chrome — no Riverpod.
class CleanPlayerView extends StatelessWidget {
  const CleanPlayerView({
    super.key,
    required this.title,
    required this.surfaceEpoch,
    required this.onBack,
    this.controller,
  });

  final String title;
  final int surfaceEpoch;
  final VideoController? controller;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null)
            Video(
              key: ValueKey('full-$surfaceEpoch'),
              controller: controller!,
              fit: BoxFit.contain,
              fill: Colors.black,
            )
          else
            const ColoredBox(color: Colors.black),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VhsColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onBack,
                      child: const Text(
                        'BACK TO VCR',
                        style: TextStyle(
                          color: VhsColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
