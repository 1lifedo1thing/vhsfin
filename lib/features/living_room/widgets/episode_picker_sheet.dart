import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/widgets/crt_loading_indicator.dart';
import 'package:vhsfin/features/living_room/widgets/deck_panel.dart';
import 'package:vhsfin/features/living_room/widgets/tape_inspect_sheet.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';
import 'package:vhsfin/user_facing_error.dart';

/// VCR-themed episode catalog for a TV series box set.
Future<void> showEpisodePicker(
  BuildContext context, {
  required Tape series,
  required String? loadedId,
  required Future<List<Tape>> Function() loadEpisodes,
  required Future<VhsSpineArt?> Function(Tape tape) resolveArt,
  required void Function(Tape episode) onInsert,
  required Future<void> Function(Tape tape) onRejectSleeve,
}) {
  return DeckFeedback.sheet(
    () => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DismissOnEscape(
        child: EpisodePickerSheet(
          series: series,
          loadedId: loadedId,
          loadEpisodes: loadEpisodes,
          resolveArt: resolveArt,
          onInsert: onInsert,
          onRejectSleeve: onRejectSleeve,
        ),
      ),
    ),
  );
}

class EpisodePickerSheet extends StatefulWidget {
  const EpisodePickerSheet({
    super.key,
    required this.series,
    required this.loadedId,
    required this.loadEpisodes,
    required this.resolveArt,
    required this.onInsert,
    required this.onRejectSleeve,
  });

  final Tape series;
  final String? loadedId;
  final Future<List<Tape>> Function() loadEpisodes;
  final Future<VhsSpineArt?> Function(Tape tape) resolveArt;
  final void Function(Tape episode) onInsert;
  final Future<void> Function(Tape tape) onRejectSleeve;

  @override
  State<EpisodePickerSheet> createState() => _EpisodePickerSheetState();
}

class _EpisodePickerSheetState extends State<EpisodePickerSheet> {
  var _busy = true;
  String? _error;
  List<Tape>? _episodes;
  final Map<String, VhsSpineArt?> _arts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final episodes = await widget.loadEpisodes();
      if (!mounted) return;
      setState(() {
        _episodes = episodes;
        _busy = false;
      });
      // Resolve sleeve art in the background; spines update as results arrive.
      for (final episode in episodes) {
        unawaited(
          widget
              .resolveArt(episode)
              .then((art) {
                if (!mounted) return;
                setState(() => _arts[episode.id] = art);
              })
              // A missing sleeve just leaves the printed spine.
              .catchError((Object _) {}),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userFacingError(error);
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final episodes = _episodes;

    return Padding(
      // Rises from the bottom edge with no gap below.
      padding: EdgeInsets.zero,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: DeckPanel(
              attachedToBottom: true,
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: DeckSheetHeader(
                      title: 'TAPE SELECT',
                      detail: episodes == null
                          ? null
                          : '${episodes.length} EPS',
                      onClose: () => Navigator.pop(context),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 2),
                    child: Text(
                      widget.series.title.toUpperCase(),
                      style: vhsBrandStyle(size: 18)
                          .copyWith(letterSpacing: 1.5),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Text(
                      'Tap a spine for the art',
                      style: TextStyle(
                        color: VhsColors.ink.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _busy
                        ? const CrtLoadingIndicator(message: 'TUNING…')
                        : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Could not load episodes.\n$_error',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: VhsColors.ink.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          )
                        : episodes == null || episodes.isEmpty
                        ? Center(
                            child: Text(
                              'No tapes in this box.',
                              style: TextStyle(
                                color: VhsColors.ink.withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              const padH = 20.0;
                              final inner = (constraints.maxWidth - padH).clamp(
                                1.0,
                                4000.0,
                              );
                              final perRow = (inner / VhsSpine.nominalWidth)
                                  .floor()
                                  .clamp(1, 100);
                              final rows = <List<Tape>>[];
                              for (
                                var i = 0;
                                i < episodes.length;
                                i += perRow
                              ) {
                                final end = (i + perRow < episodes.length)
                                    ? i + perRow
                                    : episodes.length;
                                rows.add(episodes.sublist(i, end));
                              }

                              return ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  10,
                                  0,
                                  10,
                                  16 + bottom,
                                ),
                                itemCount: rows.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, rowIndex) {
                                  final row = rows[rowIndex];
                                  return SizedBox(
                                    height: 196,
                                    child: _EpisodeShelfRow(
                                      episodes: row,
                                      arts: _arts,
                                      loadedId: widget.loadedId,
                                      onTap: (episode) {
                                        DeckFeedback.pick();
                                        showTapeInspectSheet(
                                          context,
                                          tape: episode,
                                          art: _arts[episode.id],
                                          loadArt: () =>
                                              widget.resolveArt(episode),
                                          onRejectSleeve: () =>
                                              widget.onRejectSleeve(episode),
                                          onInsert: () {
                                            Navigator.pop(context);
                                            widget.onInsert(episode);
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeShelfRow extends StatelessWidget {
  const _EpisodeShelfRow({
    required this.episodes,
    required this.arts,
    required this.loadedId,
    required this.onTap,
  });

  final List<Tape> episodes;
  final Map<String, VhsSpineArt?> arts;
  final String? loadedId;
  final ValueChanged<Tape> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var used = 0.0;
        for (final episode in episodes) {
          used += episode.id == loadedId ? 34.0 : VhsSpine.nominalWidth;
        }
        final leftover = constraints.maxWidth - used;
        const spineHeight = 148.0;
        final tips = VhsSpine.tipsForRow(
          ids: episodes.map((e) => e.id).toList(),
          leftover: leftover,
          height: spineHeight,
        );
        final leans = VhsSpine.restingOffsetsForRow(
          tips: [
            for (var i = 0; i < episodes.length; i++)
              episodes[i].id == loadedId ? 0 : tips[i],
          ],
          widths: [
            for (final episode in episodes)
              episode.id == loadedId ? 34.0 : VhsSpine.nominalWidth,
          ],
          gap: 0,
          height: spineHeight,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < episodes.length; i++)
                  VhsSpine(
                    tape: episodes[i],
                    art: arts[episodes[i].id],
                    height: spineHeight,
                    selected: episodes[i].id == loadedId,
                    tipRadians: tips[i],
                    leanOffset: leans[i],
                    onTap: () => onTap(episodes[i]),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final episode in episodes)
                  SizedBox(
                    width: episode.id == loadedId ? 34 : VhsSpine.nominalWidth,
                    child: Text(
                      episode.title,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: episode.id == loadedId
                            ? VhsColors.accent
                            : VhsColors.ink,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
