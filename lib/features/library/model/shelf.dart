import 'package:vhsfin/features/library/model/tape.dart';

/// One horizontal bookshelf row.
class Shelf {
  const Shelf({
    required this.id,
    required this.title,
    required this.items,
    this.parentSeriesId,
  });

  final String id;
  final String title;
  final List<Tape> items;

  /// When set, this shelf holds episodes for an expanded series.
  final String? parentSeriesId;

  bool get isEpisodeShelf => parentSeriesId != null;
}
