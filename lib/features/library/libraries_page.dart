import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/library/model/media_library.dart';
import 'package:vhsfin/features/library/state/tape_library.dart';
import 'package:vhsfin/features/library/views/libraries_view.dart';

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

  Future<void> _toggle(ShelfSource source) async {
    await ref.read(shelfSourcesProvider.notifier).toggle(source);
    ref.invalidate(shelvesProvider);
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

    return LibrariesView(
      connected: session != null,
      heading: stack.isEmpty ? 'LIBRARIES' : current!.name.toUpperCase(),
      breadcrumb: breadcrumb,
      selected: selected,
      childrenLoading: childrenAsync.isLoading && !childrenAsync.hasValue,
      childrenError: childrenAsync.hasError ? '${childrenAsync.error}' : null,
      children: childrenAsync.asData?.value,
      currentName: current?.name,
      currentSelected: currentSelected,
      onBack: () {
        if (stack.isNotEmpty) {
          ref.read(browseStackProvider.notifier).pop();
        } else {
          context.pop();
        }
      },
      onDone: () {
        ref.invalidate(shelvesProvider);
        context.pop();
      },
      onOpenRoot: () => ref.read(browseStackProvider.notifier).openRoot(),
      onCrumbTap: (i) => ref.read(browseStackProvider.notifier).popTo(i),
      onRemoveSource: (id) async {
        await ref.read(shelfSourcesProvider.notifier).remove(id);
        ref.invalidate(shelvesProvider);
      },
      onToggleCurrent: current == null
          ? null
          : () => _toggle(
                _sourceFor(
                  current,
                  breadcrumb.length <= 1
                      ? const []
                      : breadcrumb.sublist(0, breadcrumb.length - 1),
                ),
              ),
      onToggleNode: (node) => _toggle(_sourceFor(node, breadcrumb)),
      onOpenNode: (node) => ref.read(browseStackProvider.notifier).push(node),
    );
  }
}
