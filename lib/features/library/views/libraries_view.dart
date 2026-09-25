import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/living_room/widgets/crt_loading_indicator.dart';

/// Collection picker UI — page owns browse/selection state.
class LibrariesView extends StatelessWidget {
  const LibrariesView({
    super.key,
    required this.connected,
    required this.heading,
    required this.breadcrumb,
    required this.selected,
    required this.childrenLoading,
    required this.onBack,
    required this.onDone,
    required this.onOpenRoot,
    required this.onCrumbTap,
    required this.onRemoveSource,
    required this.onToggleNode,
    required this.onOpenNode,
    this.childrenError,
    this.children,
    this.currentName,
    this.currentSelected = false,
    this.onToggleCurrent,
  });

  final bool connected;
  final String heading;
  final List<String> breadcrumb;
  final List<ShelfSource> selected;
  final bool childrenLoading;
  final String? childrenError;
  final List<LibraryNode>? children;
  final String? currentName;
  final bool currentSelected;
  final VoidCallback onBack;
  final VoidCallback onDone;
  final VoidCallback onOpenRoot;
  final ValueChanged<int> onCrumbTap;
  final ValueChanged<String> onRemoveSource;
  final ValueChanged<LibraryNode> onToggleNode;
  final ValueChanged<LibraryNode> onOpenNode;
  final VoidCallback? onToggleCurrent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHELVES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        actions: [
          TextButton(
            onPressed: onDone,
            child: const Text(
              'DONE',
              style: TextStyle(
                color: VhsColors.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VhsColors.surface, VhsColors.room],
          ),
        ),
        child: !connected
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Connect to Jellyfin first, then add folders like Kids Movies and TV Shows as separate shelves.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(heading, style: vhsBrandStyle(size: 22)),
                            const SizedBox(height: 6),
                            Text(
                              'Add as many shelves as you want — each checked folder gets its own row under the VCR.',
                              style: TextStyle(
                                color: VhsColors.ink.withValues(alpha: 0.7),
                                height: 1.35,
                              ),
                            ),
                            if (breadcrumb.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _Crumb(label: 'Libraries', onTap: onOpenRoot),
                                  for (
                                    var i = 0;
                                    i < breadcrumb.length;
                                    i++
                                  ) ...[
                                    Text(
                                      ' › ',
                                      style: TextStyle(
                                        color: VhsColors.ink.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                    _Crumb(
                                      label: breadcrumb[i],
                                      onTap: () => onCrumbTap(i),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            if (selected.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'ON THE CONSOLE',
                                style: TextStyle(
                                  color: VhsColors.ink.withValues(alpha: 0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final source in selected)
                                    InputChip(
                                      label: Text(source.pathLabel),
                                      selected: true,
                                      selectedColor: VhsColors.accent
                                          .withValues(alpha: 0.2),
                                      checkmarkColor: VhsColors.accent,
                                      labelStyle: const TextStyle(
                                        color: VhsColors.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                      deleteIconColor: VhsColors.accent,
                                      onDeleted: () =>
                                          onRemoveSource(source.id),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (currentName != null && onToggleCurrent != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: onToggleCurrent,
                              child: Text(
                                currentSelected
                                    ? 'REMOVE “${currentName!.toUpperCase()}”'
                                    : 'ADD “${currentName!.toUpperCase()}” AS SHELF',
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _ChildrenPane(
                          loading: childrenLoading,
                          error: childrenError,
                          nodes: children,
                          atRoot: breadcrumb.isEmpty,
                          selected: selected,
                          onToggleNode: onToggleNode,
                          onOpenNode: onOpenNode,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                        child: Text(
                          'Tip: open Movies → Kids Movies and check it, then go back and check TV Shows too. Each becomes its own shelf.',
                          style: TextStyle(
                            color: VhsColors.ink.withValues(alpha: 0.45),
                            fontSize: 12,
                            height: 1.35,
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

class _ChildrenPane extends StatelessWidget {
  const _ChildrenPane({
    required this.loading,
    required this.atRoot,
    required this.selected,
    required this.onToggleNode,
    required this.onOpenNode,
    this.error,
    this.nodes,
  });

  final bool loading;
  final String? error;
  final List<LibraryNode>? nodes;
  final bool atRoot;
  final List<ShelfSource> selected;
  final ValueChanged<LibraryNode> onToggleNode;
  final ValueChanged<LibraryNode> onOpenNode;

  @override
  Widget build(BuildContext context) {
    if (loading) return const CrtLoadingIndicator();
    if (error != null) return Center(child: Text(error!));
    final list = nodes ?? const <LibraryNode>[];
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            atRoot ? 'No libraries found.' : 'No more folders here. Add this folder with the button above.',
            textAlign: TextAlign.center,
            style: TextStyle(color: VhsColors.ink.withValues(alpha: 0.7)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final node = list[index];
        final isSelected = selected.any((s) => s.id == node.id);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 4,
          ),
          minVerticalPadding: 12,
          leading: Icon(
            atRoot ? Icons.video_library_rounded : Icons.folder_rounded,
            color: isSelected ? VhsColors.accent : VhsColors.ink,
          ),
          title: Text(
            node.name,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: isSelected ? VhsColors.accent : VhsColors.ink,
            ),
          ),
          subtitle: Text(
            [
              if (node.collectionType != null) node.collectionType!,
              if (node.type != null) node.type!,
              if (node.childCount != null) '${node.childCount} items',
            ].join(' · '),
            style: TextStyle(color: VhsColors.ink.withValues(alpha: 0.55)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isSelected,
                activeColor: VhsColors.accent,
                checkColor: VhsColors.room,
                onChanged: (_) => onToggleNode(node),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => onOpenNode(node),
        );
      },
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: VhsColors.accent,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
