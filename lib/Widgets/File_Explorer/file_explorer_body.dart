import 'dart:io';
import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:intl/intl.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Services/media_scanner.dart';
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
  static const imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
  static const videoExts = ['.mp4', '.mkv', '.avi', '.3gp', '.mov'];
  static const audioExts = ['.mp3', '.wav', '.aac', '.m4a', '.ogg'];
  static const documentExts = [
    '.pdf',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
  ];
  static const apkExts = ['.apk'];

  MediaType _getMediaTypeFromExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    if (imageExts.contains(ext)) return MediaType.image;
    if (videoExts.contains(ext)) return MediaType.video;
    if (audioExts.contains(ext)) return MediaType.audio;
    if (documentExts.contains(ext)) return MediaType.document;
    if (apkExts.contains(ext)) return MediaType.apk;
    return MediaType.other;
  }

  IconData _getIconForMedia(MediaType type) {
    switch (type) {
      case MediaType.image:
        return Icons.image;
      case MediaType.video:
        return Icons.video_library;
      case MediaType.audio:
        return Icons.music_note;
      case MediaType.document:
        return Icons.insert_drive_file;
      case MediaType.apk:
        return Icons.android;
      default:
        return Icons.folder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentState = ref.watch(widget.providerInstance);
    final notifier = ref.read(widget.providerInstance.notifier);
    final lastModifiedMap = currentState.lastModifiedMap;
    return currentState.folders.isEmpty && currentState.files.isEmpty
        ? const ScreenEmptyWidget()
        : ListView.builder(
            key: const PageStorageKey('fileExplorerListView'),
            itemCount:
                (currentState.folders.isNotEmpty
                    ? currentState.folders.length + 1
                    : 0) +
                (currentState.files.isNotEmpty
                    ? currentState.files.length + 1
                    : 0),
            itemBuilder: (context, index) {
              final folderHeaderIndex = 0;
              final fileHeaderIndex = currentState.folders.isNotEmpty
                  ? currentState.folders.length + 1
                  : 0;

              if (index == folderHeaderIndex &&
                  currentState.folders.isNotEmpty) {
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
                final folderPath = currentState.folders[index - 1].path;
                final folderName = p.basename(folderPath);
                final lastModifiedDate = lastModifiedMap?[folderPath];
                return ListTile(
                  key: ValueKey(folderPath),
                  title: Text(
                    folderName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: const CircleAvatar(child: Icon(Icons.folder)),
                  subtitle: Text(
                    lastModifiedDate != null
                        ? DateFormat('dd MMM yyyy').format(lastModifiedDate)
                        : 'Last Modified: Unknown',
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
              } else if (index == fileHeaderIndex &&
                  currentState.files.isNotEmpty) {
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
                final filePath =
                    currentState.files[index - fileHeaderIndex - 1].path;
                final fileName = p.basename(filePath);
                final iconData = _getIconForMedia(
                  _getMediaTypeFromExtension(filePath),
                );
                final lastModifiedDate = lastModifiedMap?[filePath];
                return ListTile(
                  key: ValueKey(filePath),
                  title: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: CircleAvatar(child: Icon(iconData)),
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
                  subtitle: Text(
                    lastModifiedDate != null
                        ? DateFormat('dd MMM yyyy').format(lastModifiedDate)
                        : 'Last Modified: Unknown',
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
