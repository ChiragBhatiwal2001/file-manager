import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Providers/manual_drag_mode_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Services/drag_order_file_explorer.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Utils/drag_ordering_enum_file_explorer.dart';
import 'package:file_manager/Widgets/File_Explorer/order_list.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import 'file_list_tile.dart';
import 'folder_list_tile.dart';

class FileExplorerBody extends ConsumerStatefulWidget {
  final StateNotifierProvider<FileExplorerNotifier, FileExplorerState>
  providerInstance;

  const FileExplorerBody({super.key, required this.providerInstance});

  @override
  ConsumerState<FileExplorerBody> createState() => _FileExplorerBodyState();
}

class _FileExplorerBodyState extends ConsumerState<FileExplorerBody> {
  List<ExplorerItem> _reorderedItems = [];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(widget.providerInstance);
    final sortValue = state.sortValue;
    final isInDragMode = ref.watch(manualDragModeProvider);
    final isManualSort = sortValue == "drag";

    final hiddenState = ref.watch(hiddenPathsProvider);
    final showHidden = hiddenState.showHidden;
    final hiddenPaths = hiddenState.hiddenPaths;

    final visibleFolders = state.folders
        .where((entity) => showHidden || !hiddenPaths.contains(entity.path))
        .toList();
    final visibleFiles = state.files
        .where((entity) => showHidden || !hiddenPaths.contains(entity.path))
        .toList();

    if (visibleFolders.isEmpty && visibleFiles.isEmpty) {
      return const ScreenEmptyWidget();
    }

    if (_reorderedItems.isEmpty) {
      _reorderedItems = buildItemList(visibleFolders, visibleFiles);
    }

    if (isManualSort && isInDragMode) {
      return ReorderableListView.builder(
        itemCount: _reorderedItems.length,
        onReorder: (oldIndex, newIndex) async {
          final draggedItem = _reorderedItems[oldIndex];

          if (newIndex > _reorderedItems.length) newIndex = _reorderedItems.length;
          if (newIndex > oldIndex) newIndex--;

          final targetItem = _reorderedItems[newIndex];

          final isInvalidMove =
              draggedItem.type.toString().contains("Header") ||
              targetItem.type.toString().contains("Header") ||
              draggedItem.type != targetItem.type;

          if (isInvalidMove) {
            setState(() {});
            return;
          }

          setState(() {
            final movedItem = _reorderedItems.removeAt(oldIndex);
            _reorderedItems.insert(newIndex, movedItem);
          });

          final reorderedPaths = _reorderedItems
              .where(
                (item) =>
                    item.type == ExplorerItemType.folder ||
                    item.type == ExplorerItemType.file,
              )
              .map((item) => item.path!)
              .toList();

          await DragOrderStore.saveOrderForPath(
            state.currentPath,
            reorderedPaths,
          );
        },

        itemBuilder: (context, index) {
          final item = _reorderedItems[index];
          final isHidden = ref
              .watch(hiddenPathsProvider)
              .hiddenPaths
              .contains(item.path);
          switch (item.type) {
            case ExplorerItemType.folderHeader:
              return const ListTile(
                key: ValueKey("folder-header"),
                title: Text(
                  "Folders",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            case ExplorerItemType.fileHeader:
              return const ListTile(
                key: ValueKey("file-header"),
                title: Text(
                  "Files",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            case ExplorerItemType.folder:
              return ListTile(
                key: ValueKey(item.path),
                title: Text(
                  p.basename(item.path!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isHidden ? Colors.blueGrey : null),
                ),
                leading: CircleAvatar(
                  child: Icon(
                    Icons.folder,
                    color: isHidden ? Colors.grey : null,
                  ),
                ),
                subtitle: FutureBuilder<Map<String, dynamic>>(
                  future: getMetadata(item.path!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text("Loading...");
                    final data = snapshot.data!;
                    return Text(
                      "${data['Size']} | ${data['Modified']}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    );
                  },
                ),
                trailing: Icon(Icons.more_vert),
              );
            case ExplorerItemType.file:
              return ListTile(
                key: ValueKey(item.path),
                title: Text(
                  p.basename(item.path!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isHidden ? Colors.blueGrey : null),
                ),
                leading: CircleAvatar(
                  child: Icon(
                    Icons.insert_drive_file,
                    color: isHidden ? Colors.grey : null,
                  ),
                ),
                subtitle: FutureBuilder<Map<String, dynamic>>(
                  future: getMetadata(item.path!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Text("Loading...");
                    final data = snapshot.data!;
                    return Text(
                      "${data['Size']} | ${data['Modified']}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    );
                  },
                ),
                trailing: Icon(Icons.more_vert),
              );
          }
        },
      );
    }

    return ListView.builder(
      itemCount:
          (visibleFolders.isNotEmpty ? visibleFolders.length + 1 : 0) +
          (visibleFiles.isNotEmpty ? visibleFiles.length + 1 : 0),
      itemBuilder: (context, index) {
        final folderHeaderIndex = 0;
        final fileHeaderIndex = visibleFolders.isNotEmpty
            ? visibleFolders.length + 1
            : 0;

        if (index == folderHeaderIndex && visibleFolders.isNotEmpty) {
          return const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8, bottom: 0),
            child: Text(
              "Folders",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.indigoAccent,
              ),
            ),
          );
        } else if (index > folderHeaderIndex && index < fileHeaderIndex) {
          final folderPath = visibleFolders[index - 1].path;
          return FolderListTile(
            path: folderPath,
            providerInstance: widget.providerInstance,
          );
        } else if (index == fileHeaderIndex && visibleFiles.isNotEmpty) {
          return const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8, bottom: 0),
            child: Text(
              "Files",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.indigoAccent,
              ),
            ),
          );
        } else {
          final filePath = visibleFiles[index - fileHeaderIndex - 1].path;
          return FileListTile(
            path: filePath,
            providerInstance: widget.providerInstance,
          );
        }
      },
    );
  }
}
