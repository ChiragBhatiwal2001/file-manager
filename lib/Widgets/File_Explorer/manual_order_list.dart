import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../Services/drag_order_file_explorer.dart';
import '../../Services/get_meta_data.dart';
import '../../Providers/file_explorer_notifier.dart';
import '../../Providers/hide_file_folder_notifier.dart';
import '../../Utils/drag_ordering_enum_file_explorer.dart';

class ManualReorderListView extends ConsumerStatefulWidget {
  final List<ExplorerItem> initialItems;

  const ManualReorderListView({super.key, required this.initialItems});

  @override
  ConsumerState<ManualReorderListView> createState() => _ManualReorderListViewState();
}

class _ManualReorderListViewState extends ConsumerState<ManualReorderListView> {
  late List<ExplorerItem> _items;

  @override
  void initState() {
    super.initState();
    _items = [...widget.initialItems];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileExplorerProvider);
    final hiddenPaths = ref.watch(hiddenPathsProvider).hiddenPaths;

    return ReorderableListView.builder(
      itemCount: _items.length,
      onReorder: (oldIndex, newIndex) async {
        final draggedItem = _items[oldIndex];
        if (newIndex > _items.length) newIndex = _items.length;
        if (newIndex > oldIndex) newIndex--;

        final targetItem = _items[newIndex];

        final isInvalidMove = draggedItem.type != targetItem.type ||
            draggedItem.type.toString().contains("Header");

        if (isInvalidMove) {
          setState(() {});
          return;
        }

        setState(() {
          final movedItem = _items.removeAt(oldIndex);
          _items.insert(newIndex, movedItem);
        });

        final reorderedPaths = _items
            .where((item) =>
        item.type == ExplorerItemType.folder ||
            item.type == ExplorerItemType.file)
            .map((item) => item.path!)
            .toList();

        await DragOrderStore.saveOrderForPath(state.currentPath, reorderedPaths);
      },
      itemBuilder: (context, index) {
        final item = _items[index];
        final isHidden = hiddenPaths.contains(item.path);

        switch (item.type) {
          case ExplorerItemType.folderHeader:
            return const ListTile(
              key: ValueKey("folder-header"),
              title: Text("Folders", style: TextStyle(fontWeight: FontWeight.bold)),
            );
          case ExplorerItemType.fileHeader:
            return const ListTile(
              key: ValueKey("file-header"),
              title: Text("Files", style: TextStyle(fontWeight: FontWeight.bold)),
            );
          case ExplorerItemType.folder:
          case ExplorerItemType.file:
            return ListTile(
              key: ValueKey(item.path),
              title: Text(
                p.basename(item.path!),
                style: TextStyle(color: isHidden ? Colors.blueGrey : null),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              leading: CircleAvatar(
                child: Icon(
                  item.type == ExplorerItemType.folder
                      ? Icons.folder
                      : Icons.insert_drive_file,
                  color: isHidden ? Colors.grey : null,
                ),
              ),
              subtitle: FutureBuilder<Map<String, dynamic>>(
                future: getMetadata(item.path!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Text("Loading...");
                  final data = snapshot.data!;
                  final text = item.type == ExplorerItemType.folder
                      ? "${data['Modified']}"
                      : "${data['Size']} | ${data['Modified']}";
                  return Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600]));
                },
              ),
              trailing: const Icon(Icons.more_vert),
            );
        }
      },
    );
  }
}
