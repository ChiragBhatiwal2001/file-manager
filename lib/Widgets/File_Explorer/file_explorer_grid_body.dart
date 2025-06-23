import 'dart:typed_data';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';

class FileExplorerGridBody extends ConsumerWidget {
  final StateNotifierProvider<FileExplorerNotifier, FileExplorerState>
  providerInstance;

  const FileExplorerGridBody({super.key, required this.providerInstance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(providerInstance);
    final notifier = ref.read(providerInstance.notifier);
    final lastModifiedMap = currentState.lastModifiedMap;

    final allItems = [...currentState.folders, ...currentState.files];

    if (allItems.isEmpty) return const ScreenEmptyWidget();

    return GridView.builder(
      key: const PageStorageKey('fileExplorerGridView'),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        final item = allItems[index];
        final path = item.path;
        final name = p.basename(path);
        final isFolder = currentState.folders.contains(item);
        final lastModified = lastModifiedMap?[path];

        return Consumer(
          builder: (context, ref, _) {
            final selectionState = ref.watch(selectionProvider);
            final selectionNotifier = ref.read(selectionProvider.notifier);
            final isSelected = selectionState.selectedPaths.contains(path);
            final isSelectionMode = selectionState.isSelectionMode;
            return GestureDetector(
              onTap: () {
                if (isSelectionMode) {
                  selectionNotifier.toggleSelection(path);
                } else {
                  isFolder
                      ? notifier.loadAllContentOfPath(path)
                      : OpenFilex.open(path);
                }
              },
              onLongPress: () => selectionNotifier.toggleSelection(path),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Center(
                        child: FutureBuilder<Uint8List?>(
                          future: !isFolder
                              ? ThumbnailService.getThumbnail(path)
                              : null,
                          builder: (context, snapshot) {
                            Widget thumbnail;
                            if (isFolder) {
                              thumbnail = const Icon(Icons.folder, size: 64);
                            } else if (snapshot.connectionState ==
                                ConnectionState.done &&
                                snapshot.hasData &&
                                snapshot.data != null) {
                              thumbnail = ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  snapshot.data!,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                ),
                              );
                            } else {
                              final icon = MediaUtils.getIconForMedia(
                                MediaUtils.getMediaTypeFromExtension(path),
                              );
                              thumbnail = Icon(
                                icon,
                                size: 64,
                                color: Colors.blueGrey,
                              );
                            }

                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: thumbnail,
                                ),
                                if (isSelectionMode)
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        selectionNotifier.toggleSelection(path),
                                    shape: const CircleBorder(),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Expanded(
                      flex: 2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: FutureBuilder<Map<String, dynamic>>(
                              future: getMetadata(path),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Text(
                                    "Loading...",
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  );
                                } else if (snapshot.hasData) {
                                  final size = snapshot.data!['Size'];
                                  final modified = snapshot.data!['Modified'];
                                  return Text(
                                    '$size • $modified',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  );
                                } else {
                                  return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                          if (!isSelectionMode)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.more_vert, size: 20),
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (_) =>
                                      BottomSheetForSingleFileOperation(
                                        path: path,
                                        loadAgain:
                                        notifier.loadAllContentOfPath,
                                      ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
