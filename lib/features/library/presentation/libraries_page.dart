import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';
import 'package:vhsfin/features/library/model/media_library.dart';

/// Drill into libraries → folders → pick the nested collection for the shelf.
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

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final stack = ref.watch(browseStackProvider);
    final childrenAsync = ref.watch(browseChildrenProvider);
    final selected = ref.watch(shelfSourceProvider);

    final current = stack.isEmpty ? null : stack.last;
    final breadcrumb = stack.map((n) => n.name).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('COLLECTION'),
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
                    'Connect to Jellyfin first, then drill into a library and pick a folder like Kids Movies.',
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
                          stack.isEmpty ? 'LIBRARIES' : current!.name.toUpperCase(),
                          style: vhsBrandStyle(size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stack.isEmpty
                              ? 'Open a library, then choose a folder inside it for the shelf.'
                              : 'Open another folder, or use this one as the shelf.',
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
                        if (selected != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Shelf now: ${selected.pathLabel}',
                            style: const TextStyle(
                              color: VhsColors.phosphor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
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
                          await ref.read(shelfSourceProvider.notifier).select(
                                ShelfSource(
                                  id: current.id,
                                  name: current.name,
                                  breadcrumb: breadcrumb.length <= 1
                                      ? const []
                                      : breadcrumb.sublist(
                                          0,
                                          breadcrumb.length - 1,
                                        ),
                                ),
                              );
                          ref.invalidate(shelvesProvider);
                          if (context.mounted) context.pop();
                        },
                        child: Text('USE “${current.name.toUpperCase()}” AS SHELF'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: childrenAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: VhsColors.phosphor,
                        ),
                      ),
                      error: (error, _) => Center(child: Text('$error')),
                      data: (nodes) {
                        if (nodes.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                current == null
                                    ? 'No libraries found.'
                                    : 'No more folders here. Use the button above to set this folder as the shelf.',
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
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          itemCount: nodes.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final node = nodes[index];
                            final isSelected = selected?.id == node.id;
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
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                ref
                                    .read(browseStackProvider.notifier)
                                    .push(node);
                              },
                              onLongPress: () async {
                                final crumbs = [
                                  ...breadcrumb,
                                ];
                                await ref
                                    .read(shelfSourceProvider.notifier)
                                    .select(
                                      ShelfSource(
                                        id: node.id,
                                        name: node.name,
                                        breadcrumb: crumbs,
                                      ),
                                    );
                                ref.invalidate(shelvesProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Shelf set to ${node.name}',
                                      ),
                                    ),
                                  );
                                }
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
                      'Tip: open Movies → Kids Movies, then tap USE AS SHELF. Long-press a folder to select it without opening.',
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
