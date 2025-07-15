import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Services/drag_order_file_explorer.dart';
import 'package:file_manager/Utils/drag_ordering_enum_file_explorer.dart';
import 'package:file_manager/Widgets/File_Explorer/file_list_tile.dart';
import 'package:file_manager/Widgets/File_Explorer/folder_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManualReorderListView extends ConsumerStatefulWidget {
  final List<ExplorerItem> initialItems;
  final bool isReorderMode;
  final ScrollController scrollController;

  const ManualReorderListView({
    super.key,
    required this.initialItems,
    this.isReorderMode = false,
    required this.scrollController,
  });

  @override
  ConsumerState<ManualReorderListView> createState() =>
      _ManualReorderListViewState();
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
    final children = List.generate(_items.length, (index) => _buildItem(context, index));

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(overscroll: false),
      child: widget.isReorderMode
          ? ReorderableListView(
        buildDefaultDragHandles: false,
        onReorder: _handleReorder,
        children: children,
      )
          : ListView.builder(
        controller: widget.scrollController,
        itemCount: _items.length,
        itemBuilder: _buildItem,
      ),
    );
  }


  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];

    if (item.type == ExplorerItemType.folderHeader) {
      return const Padding(
        key: ValueKey("folder-header"),
        padding: EdgeInsets.only(left: 12.0, top: 8, bottom: 0),
        child: Text("Folders", style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (item.type == ExplorerItemType.fileHeader) {
      return const Padding(
        key: ValueKey("file-header"),
        padding: EdgeInsets.only(left: 12.0, top: 8, bottom: 0),
        child: Text("Files", style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (item.type == ExplorerItemType.folder) {
      final folderTile = FolderListTile(
        key: ValueKey(item.path),
        isDrag: widget.isReorderMode,
        path: item.path!,
      );

      return widget.isReorderMode
          ? ReorderableDragStartListener(
        key: ValueKey('folder-${item.path}'),
        index: index,
        child: folderTile,
      )
          : folderTile;
    }

    if (item.type == ExplorerItemType.file) {
      final fileTile = FileListTile(
        key: ValueKey('${item.path}-$index'),
        isDrag: widget.isReorderMode,
        path: item.path!,
      );

      return widget.isReorderMode
          ? ReorderableDragStartListener(
        key: ValueKey('file-${item.path}-$index'),
        index: index,
        child: fileTile,
      )
          : fileTile;
    }

    return const SizedBox();
  }

  void _handleReorder(int oldIndex, int newIndex) async {
    if (newIndex > _items.length) newIndex = _items.length;
    if (newIndex > oldIndex) newIndex--;

    final draggedItem = _items[oldIndex];
    final targetItem = _items[newIndex];

    final isInvalidMove =
        draggedItem.type != targetItem.type ||
            draggedItem.type.toString().contains("Header");

    if (isInvalidMove) {
      setState(() {}); // Just trigger rebuild
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

    final currentPath = ref.read(fileExplorerProvider).currentPath;
    await DragOrderStore.saveOrderForPath(currentPath, reorderedPaths);
  }
}
