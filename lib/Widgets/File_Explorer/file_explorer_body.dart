import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:flutter/foundation.dart';
import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';

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

    final notifier = ref.read(widget.providerInstance.notifier);

    final hiddenState = ref.watch(hiddenPathsProvider);
    final showHidden = hiddenState.showHidden;
    final hiddenPaths = hiddenState.hiddenPaths;

    final visibleFolders = currentState.folders.where((entity) {
      return showHidden || !hiddenPaths.contains(entity.path);
    }).toList();

    final visibleFiles = currentState.files.where((entity) {
      return showHidden || !hiddenPaths.contains(entity.path);
    }).toList();

    return visibleFolders.isEmpty && visibleFiles.isEmpty
        ? const ScreenEmptyWidget()
        : ListView.builder(
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
                final folderName = p.basename(folderPath);
                final isHidden = hiddenPaths.contains(folderPath);

                return ListTile(
                  key: ValueKey(folderPath),
                  title: Text(
                    folderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: isHidden ? Colors.blueGrey : null),
                  ),
                  subtitle: FutureBuilder<Map<String, dynamic>>(
                    future: getMetadata(folderPath), // or folderPath
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("Loading...");
                      final data = snapshot.data!;
                      return Text(
                        "${data['Size']} | ${data['Modified']}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      );
                    },
                  ),
                  leading: CircleAvatar(
                    child: Icon(
                      Icons.folder,
                      color: isHidden ? Colors.grey : null,
                    ),
                  ),

                  trailing: Consumer(
                    builder: (context, ref, _) {
                      final selectionState = ref.watch(selectionProvider);
                      final selectionNotifier = ref.read(
                        selectionProvider.notifier,
                      );
                      return selectionState.isSelectionMode
                          ? Checkbox(
                              value: selectionState.selectedPaths.contains(
                                folderPath,
                              ),
                              onChanged: (_) =>
                                  selectionNotifier.toggleSelection(folderPath),
                            )
                          : IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) =>
                                      BottomSheetForSingleFileOperation(
                                        path: folderPath,
                                        loadAgain:
                                            notifier.loadAllContentOfPath,
                                      ),
                                );
                              },
                              icon: const Icon(Icons.more_vert),
                            );
                    },
                  ),
                  onTap: () {
                    final isSelectionMode = ref
                        .read(selectionProvider)
                        .isSelectionMode;
                    final notifierSel = ref.read(selectionProvider.notifier);
                    if (isSelectionMode) {
                      notifierSel.toggleSelection(folderPath);
                    } else {
                      notifier.loadAllContentOfPath(folderPath);
                    }
                  },
                  onLongPress: () {
                    ref
                        .read(selectionProvider.notifier)
                        .toggleSelection(folderPath);
                  },
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
                final fileName = p.basename(filePath);
                final iconData = MediaUtils.getIconForMedia(
                  MediaUtils.getMediaTypeFromExtension(filePath),
                );

                return ListTile(
                  key: ValueKey(filePath),
                  title: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: FutureBuilder<Map<String, dynamic>>(
                    future: getMetadata(filePath), // or folderPath
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Text("Loading...");
                      final data = snapshot.data!;
                      return Text(
                        "${data['Size']} | ${data['Modified']}",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      );
                    },
                  ),
                  leading: FutureBuilder<Uint8List?>(
                    future: ThumbnailService.getThumbnail(filePath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            snapshot.data!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        );
                      } else {
                        return CircleAvatar(child: Icon(iconData));
                      }
                    },
                  ),
                  trailing: Consumer(
                    builder: (context, ref, _) {
                      final selectionState = ref.watch(selectionProvider);
                      final selectionNotifier = ref.read(
                        selectionProvider.notifier,
                      );
                      return selectionState.isSelectionMode
                          ? Checkbox(
                              value: selectionState.selectedPaths.contains(
                                filePath,
                              ),
                              onChanged: (_) =>
                                  selectionNotifier.toggleSelection(filePath),
                            )
                          : IconButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) =>
                                      BottomSheetForSingleFileOperation(
                                        path: filePath,
                                        loadAgain:
                                            notifier.loadAllContentOfPath,
                                      ),
                                );
                              },
                              icon: const Icon(Icons.more_vert),
                            );
                    },
                  ),
                  onTap: () {
                    final isSelectionMode = ref
                        .read(selectionProvider)
                        .isSelectionMode;
                    final notifierSel = ref.read(selectionProvider.notifier);
                    if (isSelectionMode) {
                      notifierSel.toggleSelection(filePath);
                    } else {
                      OpenFilex.open(filePath);
                    }
                  },
                  onLongPress: () {
                    ref
                        .read(selectionProvider.notifier)
                        .toggleSelection(filePath);
                  },
                );
              }
            },
          );
  }
}
