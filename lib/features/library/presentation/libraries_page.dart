import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/living_room/presentation/crt_loading_indicator.dart';

/// Drill into libraries → folders → toggle multiple collections onto shelves.
class LibrariesPage extends ConsumerStatefulWidget {
  const LibrariesPage({super.key});

  @override
  ConsumerState<LibrariesPage> createState() => _LibrariesPageState();
}

class _LibrariesPageState extends ConsumerState<LibrariesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(browseStackProvider.notifier).openRoot();
    });
  }

  ShelfSource _sourceFor(LibraryNode node, List<String> breadcrumb) {
    return ShelfSource(
      id: node.id,
      name: node.name,
      breadcrumb: breadcrumb,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final stack = ref.watch(browseStackProvider);
    final childrenAsync = ref.watch(browseChildrenProvider);
    final selected = ref.watch(shelfSourcesProvider);

    final current = stack.isEmpty ? null : stack.last;
    final breadcrumb = stack.map((n) => n.name).toList();
    final currentSelected =
        current != null && selected.any((s) => s.id == current.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SHELVES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (stack.isNotEmpty) {
              ref.read(browseStackProvider.notifier).pop();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.invalidate(shelvesProvider);
              context.pop();
            },
            child: const Text(
              'DONE',
              style: TextStyle(
                color: VhsColors.phosphor,
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
            colors: [VhsColors.woodMid, VhsColors.woodDeep],
          ),
        ),
        child: session == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Connect to Jellyfin first, then add folders like Kids Movies and TV Shows as separate shelves.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stack.isEmpty
                              ? 'LIBRARIES'
                              : current!.name.toUpperCase(),
                          style: vhsBrandStyle(size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add as many shelves as you want — each checked folder gets its own row under the VCR.',
                          style: TextStyle(
                            color: VhsColors.brand.withValues(alpha: 0.7),
                          ),
                        ),
                        if (breadcrumb.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _Crumb(
                                label: 'Libraries',
                                onTap: () => ref
                                    .read(browseStackProvider.notifier)
                                    .openRoot(),
                              ),
                              for (var i = 0; i < breadcrumb.length; i++) ...[
                                Text(
                                  ' › ',
                                  style: TextStyle(
                                    color:
                                        VhsColors.brand.withValues(alpha: 0.4),
                                  ),
                                ),
                                _Crumb(
                                  label: breadcrumb[i],
                                  onTap: () => ref
                                      .read(browseStackProvider.notifier)
                                      .popTo(i),
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
                              color: VhsColors.brand.withValues(alpha: 0.55),
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
                                  selectedColor:
                                      VhsColors.phosphor.withValues(alpha: 0.2),
                                  checkmarkColor: VhsColors.phosphor,
                                  labelStyle: const TextStyle(
                                    color: VhsColors.phosphor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  deleteIconColor: VhsColors.phosphor,
                                  onDeleted: () async {
                                    await ref
                                        .read(shelfSourcesProvider.notifier)
                                        .remove(source.id);
                                    ref.invalidate(shelvesProvider);
                                  },
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (current != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref.read(shelfSourcesProvider.notifier).toggle(
                                _sourceFor(
                                  current,
                                  breadcrumb.length <= 1
                                      ? const []
                                      : breadcrumb.sublist(
                                          0,
                                          breadcrumb.length - 1,
                                        ),
                                ),
                              );
                          ref.invalidate(shelvesProvider);
                        },
                        child: Text(
                          currentSelected
                              ? 'REMOVE “${current.name.toUpperCase()}”'
                              : 'ADD “${current.name.toUpperCase()}” AS SHELF',
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: childrenAsync.when(
                      loading: () => const CrtLoadingIndicator(),
                      error: (error, _) => Center(child: Text('$error')),
                      data: (nodes) {
                        if (nodes.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                current == null
                                    ? 'No libraries found.'
                                    : 'No more folders here. Add this folder with the button above.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color:
                                      VhsColors.brand.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
                          itemCount: nodes.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final node = nodes[index];
                            final isSelected =
                                selected.any((s) => s.id == node.id);
                            final crumbsForNode = [...breadcrumb];
                            return ListTile(
                              leading: Icon(
                                stack.isEmpty
                                    ? Icons.video_library_rounded
                                    : Icons.folder_rounded,
                                color: isSelected
                                    ? VhsColors.phosphor
                                    : VhsColors.brand,
                              ),
                              title: Text(
                                node.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? VhsColors.phosphor
                                      : VhsColors.brand,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (node.collectionType != null)
                                    node.collectionType!,
                                  if (node.type != null) node.type!,
                                  if (node.childCount != null)
                                    '${node.childCount} items',
                                ].join(' · '),
                                style: TextStyle(
                                  color:
                                      VhsColors.brand.withValues(alpha: 0.55),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: VhsColors.phosphor,
                                    checkColor: VhsColors.woodDeep,
                                    onChanged: (_) async {
                                      await ref
                                          .read(shelfSourcesProvider.notifier)
                                          .toggle(
                                            _sourceFor(node, crumbsForNode),
                                          );
                                      ref.invalidate(shelvesProvider);
                                    },
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () {
                                ref
                                    .read(browseStackProvider.notifier)
                                    .push(node);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Text(
                      'Tip: open Movies → Kids Movies and check it, then go back and check TV Shows too. Each becomes its own shelf.',
                      style: TextStyle(
                        color: VhsColors.brand.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
      ),
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
          color: VhsColors.phosphor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
