/// A browsable Jellyfin node — top-level library, folder, or box set.
class LibraryNode {
  const LibraryNode({
    required this.id,
    required this.name,
    this.type,
    this.collectionType,
    this.childCount,
    this.isFolder = false,
  });

  final String id;
  final String name;
  final String? type;
  final String? collectionType;
  final int? childCount;
  final bool isFolder;

  bool get canBrowse => isFolder;

  bool get isMovies =>
      collectionType?.toLowerCase() == 'movies' ||
      collectionType?.toLowerCase() == 'homevideos';

  bool get isTv => collectionType?.toLowerCase() == 'tvshows';

  factory LibraryNode.fromItem(Map<String, dynamic> item) {
    final type = item['Type'] as String? ?? '';
    final isFolder = type == 'Folder' ||
        type == 'CollectionFolder' ||
        type == 'UserView' ||
        type == 'BoxSet' ||
        type == 'ManualPlaylistsFolder' ||
        (item['IsFolder'] as bool? ?? false);
    return LibraryNode(
      id: item['Id'] as String,
      name: item['Name'] as String? ?? 'Untitled',
      type: type,
      collectionType: item['CollectionType'] as String?,
      childCount: item['ChildCount'] as int?,
      isFolder: isFolder,
    );
  }
}

/// The folder/library currently driving the wooden tape shelf.
class ShelfSource {
  const ShelfSource({
    required this.id,
    required this.name,
    this.breadcrumb = const [],
  });

  final String id;
  final String name;
  final List<String> breadcrumb;

  String get pathLabel {
    if (breadcrumb.isEmpty) return name;
    return [...breadcrumb, name].join(' › ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'breadcrumb': breadcrumb,
      };

  factory ShelfSource.fromJson(Map<String, dynamic> json) {
    return ShelfSource(
      id: json['id'] as String,
      name: json['name'] as String,
      breadcrumb: (json['breadcrumb'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }
}
