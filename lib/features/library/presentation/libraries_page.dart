import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/library/data/tape_library_provider.dart';

class LibrariesPage extends ConsumerWidget {
  const LibrariesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final librariesAsync = ref.watch(librariesProvider);
    final selected = ref.watch(selectedLibraryIdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SHELVES'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
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
                    'Connect to Jellyfin first, then choose which libraries appear on the bookshelf.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : librariesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: VhsColors.phosphor),
                ),
                error: (error, _) => Center(child: Text('$error')),
                data: (libraries) {
                  if (libraries.isEmpty) {
                    return const Center(child: Text('No libraries found.'));
                  }
                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text('WHICH LIBRARIES?', style: vhsBrandStyle(size: 22)),
                      const SizedBox(height: 8),
                      Text(
                        'Only checked libraries show as shelves. Movies sit as spines; TV shows are one spine that expands into episodes.',
                        style: TextStyle(
                          color: VhsColors.brand.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...libraries.map((library) {
                        final checked = selected.contains(library.id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) {
                            ref
                                .read(selectedLibraryIdsProvider.notifier)
                                .toggle(library.id);
                            ref.invalidate(shelvesProvider);
                          },
                          activeColor: VhsColors.phosphor,
                          checkColor: VhsColors.woodDeep,
                          title: Text(
                            library.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            library.collectionType ?? 'library',
                            style: TextStyle(
                              color: VhsColors.brand.withValues(alpha: 0.55),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
