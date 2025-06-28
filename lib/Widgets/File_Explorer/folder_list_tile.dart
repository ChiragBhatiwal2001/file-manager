import 'dart:io';

import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:path/path.dart' as p;

class FolderListTile extends ConsumerStatefulWidget {
  final String path;

  final bool isDrag;

  const FolderListTile({super.key, required this.path, this.isDrag = false});

  @override
  ConsumerState<FolderListTile> createState() => _FolderListTileState();
}

class _FolderListTileState extends ConsumerState<FolderListTile> {
  Map<String, dynamic>? _metadata;
  int? _contentCount;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
    _loadContentCount();
  }

  void _loadMetadata() async {
    final meta = await getMetadata(widget.path);
    if (mounted) {
      setState(() {
        _metadata = meta;
      });
    }
  }

  void _loadContentCount() async {
    try {
      final dir = Directory(widget.path);
      if (!await dir.exists()) return;

      final hiddenState = ref.read(hiddenPathsProvider);
      final showHidden = hiddenState.showHidden;
      final hiddenPaths = hiddenState.hiddenPaths;

      final List<FileSystemEntity> rawList = await dir
          .list(recursive: false)
          .toList();

      final visibleList = rawList.where((entity) {
        final path = entity.path;
        final name = p.basename(path);

        // ✅ 1. Skip system/hidden entries
        if (!showHidden && name.startsWith('.')) return false;

        // ✅ 2. Skip if app-marked as hidden
        if (!showHidden && hiddenPaths.contains(path)) return false;

        // ✅ 3. Skip not-found entries (broken symlinks etc.)
        try {
          if (FileSystemEntity.typeSync(path) ==
              FileSystemEntityType.notFound) {
            return false;
          }
        } catch (_) {
          return false;
        }

        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _contentCount = visibleList.length;
        });
      }
    } catch (e) {
      debugPrint("Error while counting visible contents of ${widget.path}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHidden = ref
        .watch(hiddenPathsProvider)
        .hiddenPaths
        .contains(widget.path);
    final folderName = p.basename(widget.path);
    final selection = ref.watch(selectionProvider);

    return ListTile(
      key: ValueKey(widget.path),
      title: Text(
        folderName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isHidden ? Colors.blueGrey : null),
      ),
      subtitle: _metadata != null
          ? Text(
              "${_contentCount ?? 0} items | ${_metadata!['Modified']}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : const Text("Loading..."),
      leading: widget.isDrag
          ? null
          : CircleAvatar(
              child: Icon(Icons.folder, color: isHidden ? Colors.grey : null),
            ),
      trailing: _buildTrailing(context, selection),
      onTap: () async {
        if (!mounted) return;

        if (selection.isSelectionMode) {
          ref.read(selectionProvider.notifier).toggleSelection(widget.path);
        } else {
          try {
            await ref
                .read(fileExplorerProvider.notifier)
                .loadAllContentOfPath(widget.path);
          } catch (e) {
            debugPrint("Safe fallback — provider might be disposed: $e");
          }
        }
      },

      onLongPress: () {
        if (!widget.isDrag) {
          ref.read(selectionProvider.notifier).toggleSelection(widget.path);
        }
      },
    );
  }

  Widget _buildTrailing(BuildContext context, SelectionState selection) {
    if (selection.isSelectionMode) {
      return Checkbox(
        value: selection.selectedPaths.contains(widget.path),
        onChanged: (_) {
          ref.read(selectionProvider.notifier).toggleSelection(widget.path);
        },
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () async {
          final result = await showModalBottomSheet(
            context: context,
            builder: (context) => BottomSheetForSingleFileOperation(
              path: widget.path,
              loadAgain: ref
                  .read(fileExplorerProvider.notifier)
                  .loadAllContentOfPath,
            ),
          );
          if (result == true && mounted) {
            ref
                .read(fileExplorerProvider.notifier)
                .loadAllContentOfPath(p.dirname(widget.path));
          }
        },
      );
    }
  }
}
