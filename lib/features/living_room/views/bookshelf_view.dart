import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/vhs_cover_resolver.dart';
import 'package:vhsfin/features/library/data/vhs_image_cache.dart';
import 'package:vhsfin/features/library/model/shelf.dart';
import 'package:vhsfin/features/library/model/tape.dart';
import 'package:vhsfin/features/living_room/state/tape_flight_anchors.dart';
import 'package:vhsfin/features/living_room/widgets/crt_loading_indicator.dart';
import 'package:vhsfin/features/living_room/widgets/vhs_spine.dart';

/// Bookshelf content — props only; page owns Riverpod.
class BookshelfView extends StatelessWidget {
  const BookshelfView({
    super.key,
    required this.shelves,
    required this.loadedId,
    required this.loadedSeriesId,
    required this.vhsOnly,
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.resolveSpineArt,
    required this.onTapeTap,
    this.embedded = false,
  });

  /// When true, sits inside the wooden entertainment center.
  final bool embedded;
  final List<Shelf> shelves;
  final String? loadedId;
  final String? loadedSeriesId;
  final bool vhsOnly;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final void Function(Tape tape, String instanceKey) onTapeTap;

  @override
  Widget build(BuildContext context) {
    if (shelves.isEmpty) {
      return const Text('No tapes on these shelves yet.');
    }
    return Column(
      children: [
        for (var i = 0; i < shelves.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _ShelfBlock(
            shelf: shelves[i],
            loadedId: loadedId,
            loadedSeriesId: loadedSeriesId,
            embedded: embedded,
            showTitle: !embedded || shelves.length > 1,
            vhsOnly: vhsOnly,
            flightAnchors: flightAnchors,
            flyingTapeId: flyingTapeId,
            flightSourceKey: flightSourceKey,
            resolveSpineArt: resolveSpineArt,
            onTapeTap: onTapeTap,
          ),
        ],
      ],
    );
  }
}

class _ShelfBlock extends StatelessWidget {
  const _ShelfBlock({
    required this.shelf,
    required this.loadedId,
    required this.loadedSeriesId,
    required this.embedded,
    required this.showTitle,
    required this.vhsOnly,
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.resolveSpineArt,
    required this.onTapeTap,
  });

  final Shelf shelf;
  final String? loadedId;
  final String? loadedSeriesId;
  final bool embedded;
  final bool showTitle;
  final bool vhsOnly;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final void Function(Tape tape, String instanceKey) onTapeTap;

  /// Pack at upright spine thickness + a hair of air between tapes.
  static const _spineGap = 2.0;
  static const _spineSlotWidth = VhsSpine.nominalWidth + _spineGap;
  // Room for upright spines + lean slack inside the bay.
  static const _rowHeight = 192.0;
  static const _lipHeight = 8.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              shelf.title,
              style: vhsBrandStyle(size: 13).copyWith(letterSpacing: 2),
            ),
          ),
        if (shelf.items.isEmpty)
          _shelfBay(
            child: Center(
              child: Text(
                shelf.id == 'connect'
                    ? 'Connect to load your tapes'
                    : shelf.id == 'empty'
                    ? 'Pick collections below'
                    : vhsOnly
                        ? 'No VHS titles on this shelf'
                        : 'Empty shelf',
                style: TextStyle(
                  color: VhsColors.brand.withValues(alpha: 0.55),
                ),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Inner cavity width after horizontal padding.
              const padH = 16.0;
              final inner = (constraints.maxWidth - padH).clamp(1.0, 4000.0);
              final perRow = (inner / _spineSlotWidth).floor().clamp(1, 100);
              final rows = <List<Tape>>[];
              for (var i = 0; i < shelf.items.length; i += perRow) {
                final end = (i + perRow < shelf.items.length)
                    ? i + perRow
                    : shelf.items.length;
                rows.add(shelf.items.sublist(i, end));
              }

              return _ShelfArtReveal(
                tapes: shelf.items,
                resolveSpineArt: resolveSpineArt,
                builder: (arts) => Column(
                  children: [
                    for (var r = 0; r < rows.length; r++) ...[
                      if (r > 0) const SizedBox(height: 10),
                      _shelfBay(
                        child: _ShelfTapeRow(
                          shelfId: shelf.id,
                          rowIndex: r,
                          tapes: rows[r],
                          arts: arts,
                          loadedId: loadedId,
                          loadedSeriesId: loadedSeriesId,
                          gap: _spineGap,
                          flightAnchors: flightAnchors,
                          flyingTapeId: flyingTapeId,
                          flightSourceKey: flightSourceKey,
                          onTap: onTapeTap,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  /// Cavity + lip as one unit so spine bases sit on the wood edge.
  Widget _shelfBay({required Widget child}) {
    return SizedBox(
      height: _rowHeight + _lipHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: _lipHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                color: Colors.black.withValues(alpha: embedded ? 0.28 : 0.22),
                border: Border.all(color: Colors.black.withValues(alpha: 0.35)),
              ),
              child: Padding(
                // No bottom pad — spines rest on the cavity floor / lip seam.
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                child: child,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _lipHeight,
            child: const CustomPaint(painter: ShelfLipPainter()),
          ),
        ],
      ),
    );
  }
}

/// Holds the shelf at opacity 0 until every tape's sleeve bytes are warmed,
/// then fades the whole bay in together.
class _ShelfArtReveal extends StatefulWidget {
  const _ShelfArtReveal({
    required this.tapes,
    required this.resolveSpineArt,
    required this.builder,
  });

  final List<Tape> tapes;
  final Future<VhsSpineArt?> Function(Tape tape) resolveSpineArt;
  final Widget Function(Map<String, VhsSpineArt?> arts) builder;

  @override
  State<_ShelfArtReveal> createState() => _ShelfArtRevealState();
}

class _ShelfArtRevealState extends State<_ShelfArtReveal> {
  static const _fade = Duration(milliseconds: 520);
  static const _budget = Duration(seconds: 12);

  var _visible = false;
  String? _warmKey;
  int _warmGen = 0;
  Timer? _budgetTimer;
  Map<String, VhsSpineArt?> _arts = const {};

  @override
  void initState() {
    super.initState();
    _scheduleWarm();
  }

  @override
  void dispose() {
    _budgetTimer?.cancel();
    _warmGen++;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ShelfArtReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_tapeKey(oldWidget.tapes) != _tapeKey(widget.tapes)) {
      // Sync before the follow-up build so we never paint one frame of the
      // previous (or next) shelf at full opacity.
      _visible = false;
      _budgetTimer?.cancel();
      _budgetTimer = null;
      _scheduleWarm();
    }
  }

  String _tapeKey(List<Tape> tapes) => tapes.map((t) => t.id).join('|');

  void _scheduleWarm() {
    final key = _tapeKey(widget.tapes);
    _warmKey = key;
    final gen = ++_warmGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _warmGen) return;
      _warm(key, gen);
    });
  }

  Future<void> _warm(String key, int gen) async {
    try {
      await Future.any<void>([
        _prefetch(widget.tapes),
        _budgetGate(),
      ]);
    } catch (_) {
      // Still reveal — procedural spines / errors shouldn't trap the bay.
    } finally {
      _budgetTimer?.cancel();
      _budgetTimer = null;
    }
    if (!mounted || gen != _warmGen || _warmKey != key) return;
    setState(() => _visible = true);
  }

  Future<void> _budgetGate() {
    _budgetTimer?.cancel();
    final gate = Completer<void>();
    _budgetTimer = Timer(_budget, gate.complete);
    return gate.future;
  }

  Future<void> _prefetch(List<Tape> tapes) async {
    if (tapes.isEmpty) return;

    final arts = await Future.wait(
      tapes.map(widget.resolveSpineArt),
    );

    final byId = <String, VhsSpineArt?>{};
    final urls = <String>{};
    for (var i = 0; i < tapes.length; i++) {
      final art = arts[i];
      byId[tapes[i].id] = art;
      if (art != null) {
        urls.add(art.imageUrl);
        final front = art.frontImageUrl;
        if (front != null && front.isNotEmpty) urls.add(front);
      } else {
        final poster = tapes[i].imageUrl;
        if (poster != null && poster.isNotEmpty) urls.add(poster);
      }
    }

    if (mounted) setState(() => _arts = byId);

    if (!mounted || urls.isEmpty) return;

    // One failure must not abort the rest — on web CORS/file-cache misses used
    // to trip Future.wait and reveal a blank shelf while <img> loads continued.
    await Future.wait(
      urls.map((url) async {
        try {
          await VhsImageCache.warm(url, context: context);
        } catch (error) {
          debugPrint('vhs-art warm miss $url: $error');
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: _fade,
          curve: Curves.easeOutCubic,
          child: IgnorePointer(
            ignoring: !_visible,
            child: widget.builder(_arts),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _visible,
            child: AnimatedOpacity(
              opacity: _visible ? 0 : 1,
              duration: _fade,
              curve: Curves.easeOutCubic,
              child: const ColoredBox(
                color: Color(0x66000000),
                child: CrtLoadingIndicator(
                  compact: true,
                  style: CrtLoadStyle.tape,
                  message: 'LOADING VHS ART',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Packed left-aligned spines; trailing tape bookends left when space remains.
class _ShelfTapeRow extends StatelessWidget {
  const _ShelfTapeRow({
    required this.shelfId,
    required this.rowIndex,
    required this.tapes,
    required this.arts,
    required this.loadedId,
    required this.loadedSeriesId,
    required this.flightAnchors,
    required this.flyingTapeId,
    required this.flightSourceKey,
    required this.onTap,
    this.gap = 2,
  });

  final String shelfId;
  final int rowIndex;
  final List<Tape> tapes;
  final Map<String, VhsSpineArt?> arts;
  final String? loadedId;
  final String? loadedSeriesId;
  final TapeFlightAnchors flightAnchors;
  final String? flyingTapeId;
  final String? flightSourceKey;
  final void Function(Tape tape, String instanceKey) onTap;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var used = tapes.isEmpty ? 0.0 : (tapes.length - 1) * gap;
        for (final tape in tapes) {
          final selected = tape.id == loadedId ||
              (tape.kind == TapeKind.series && tape.id == loadedSeriesId);
          used += selected ? 34.0 : VhsSpine.nominalWidth;
        }
        final leftover = constraints.maxWidth - used;
        const baseHeight = 168.0;
        final tips = VhsSpine.tipsForRow(
          ids: tapes.map((t) => t.id).toList(),
          leftover: leftover,
          height: baseHeight,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < tapes.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              () {
                final instanceKey = TapeFlightAnchors.instanceKey(
                  shelfId: shelfId,
                  row: rowIndex,
                  index: i,
                  tapeId: tapes[i].id,
                );
                final isSource = flightSourceKey == instanceKey;
                return RepaintBoundary(
                  child: KeyedSubtree(
                    // GlobalKey only on the tapped instance — duplicates stay put.
                    key: isSource
                        ? flightAnchors.spineKeyFor(instanceKey)
                        : ValueKey(instanceKey),
                    child: VhsSpine(
                      tape: tapes[i],
                      art: arts[tapes[i].id],
                      height: baseHeight,
                      selected: tapes[i].id == loadedId ||
                          (tapes[i].kind == TapeKind.series &&
                              tapes[i].id == loadedSeriesId),
                      tipRadians: tips[i],
                      ghosted: flyingTapeId == tapes[i].id && isSource,
                      onTap: () => onTap(tapes[i], instanceKey),
                    ),
                  ),
                );
              }(),
            ],
          ],
        );
      },
    );
  }
}
