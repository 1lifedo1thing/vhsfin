/// A Jellyfin media library / view the user can include on the bookshelf.
class MediaLibrary {
  const MediaLibrary({
    required this.id,
    required this.name,
    this.collectionType,
  });

  final String id;
  final String name;
  final String? collectionType;

  bool get isMovies =>
      collectionType?.toLowerCase() == 'movies' ||
      collectionType?.toLowerCase() == 'homevideos';

  bool get isTv => collectionType?.toLowerCase() == 'tvshows';
}
