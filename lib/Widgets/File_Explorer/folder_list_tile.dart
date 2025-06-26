import 'dart:io';

import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:path/path.dart' as p;

class FolderListTile extends ConsumerStatefulWidget {
  final String path;
  final StateNotifierProvider<FileExplorerNotifier, FileExplorerState>
  providerInstance;
  final bool isDrag;

  const FolderListTile({
    super.key,
    required this.path,
    this.isDrag = false,
    required this.providerInstance,
  });

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
      if (await dir.exists()) {
        final list = await dir.list().toList();
        if (mounted) {
          setState(() {
            _contentCount = list.length;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isHidden = ref
        .watch(hiddenPathsProvider)
        .hiddenPaths
        .contains(widget.path);
    final folderName = p.basename(widget.path);
    final selection = ref.watch(selectionProvider);
    final notifier = ref.read(widget.providerInstance.notifier);

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
              "$_contentCount items | ${_metadata!['Modified']}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : const Text("Loading..."),
      leading: widget.isDrag
          ? null
          : CircleAvatar(
              child: Icon(Icons.folder, color: isHidden ? Colors.grey : null),
            ),
      trailing: _buildTrailing(context, selection),
      onTap: () {
        if (selection.isSelectionMode) {
          ref.read(selectionProvider.notifier).toggleSelection(widget.path);
        } else {
          notifier.loadAllContentOfPath(widget.path);
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
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => BottomSheetForSingleFileOperation(
              path: widget.path,
              loadAgain: ref
                  .read(widget.providerInstance.notifier)
                  .loadAllContentOfPath,
            ),
          );
        },
      );
    }
  }
}
