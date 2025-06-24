import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  Widget build(BuildContext context) {
    final currentState = ref.watch(widget.providerInstance);

    final hiddenState = ref.watch(hiddenPathsProvider);
    final showHidden = hiddenState.showHidden;
    final hiddenPaths = hiddenState.hiddenPaths;

    final visibleFolders = currentState.folders
        .where((entity) => showHidden || !hiddenPaths.contains(entity.path))
        .toList();
    final visibleFiles = currentState.files
        .where((entity) => showHidden || !hiddenPaths.contains(entity.path))
        .toList();

    if (visibleFolders.isEmpty && visibleFiles.isEmpty) {
      return const ScreenEmptyWidget();
    }

    return ListView.builder(
      itemCount: (visibleFolders.isNotEmpty ? visibleFolders.length + 1 : 0) +
          (visibleFiles.isNotEmpty ? visibleFiles.length + 1 : 0),
      itemBuilder: (context, index) {
        final folderHeaderIndex = 0;
        final fileHeaderIndex =
        visibleFolders.isNotEmpty ? visibleFolders.length + 1 : 0;

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
