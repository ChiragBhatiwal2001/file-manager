import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';

class FileGridTile extends ConsumerStatefulWidget {
  final FileSystemEntity entity;
  final bool isFolder;
  final FileExplorerNotifier notifier;

  const FileGridTile({
    super.key,
    required this.entity,
    required this.isFolder,
    required this.notifier,
  });

  @override
  ConsumerState<FileGridTile> createState() => _FileGridTileState();
}

class _FileGridTileState extends ConsumerState<FileGridTile> {
  Uint8List? _thumbnail;
  Map<String, dynamic>? _metadata;

  @override
  void initState() {
    super.initState();
    _loadThumbnailAndMetadata();
  }

  void _loadThumbnailAndMetadata() async {
    final path = widget.entity.path;
    if (!widget.isFolder) {
      final thumb = await ThumbnailService.getThumbnail(path);
      if (mounted) {
        setState(() {
          _thumbnail = thumb;
        });
      }
    }

    final meta = await getMetadata(path);
    if (mounted) {
      setState(() {
        _metadata = meta;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.entity.path;
    final name = p.basename(path);

    final selection = ref.watch(selectionProvider);
    final isSelected = selection.selectedPaths.contains(path);
    final isSelectionMode = selection.isSelectionMode;
    final selectionNotifier = ref.read(selectionProvider.notifier);

    final Widget thumbnailWidget = widget.isFolder
        ? const Icon(Icons.folder, size: 64)
        : _thumbnail != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _thumbnail!,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          )
        : Icon(
            MediaUtils.getIconForMedia(
              MediaUtils.getMediaTypeFromExtension(path),
            ),
            size: 64,
            color: Colors.blueGrey,
          );

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          selectionNotifier.toggleSelection(path);
        } else {
          widget.isFolder
              ? widget.notifier.loadAllContentOfPath(path)
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
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Align(alignment: Alignment.center, child: thumbnailWidget),
                    if (isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) =>
                            selectionNotifier.toggleSelection(path),
                        shape: const CircleBorder(),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Expanded(
              flex: 2,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _metadata != null
                        ? Text(
                            '${_metadata!['Size']} • ${_metadata!['Modified']}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        : const Text(
                            "Loading...",
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                  ),
                  if (!isSelectionMode)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () {
                        showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          builder: (_) => BottomSheetForSingleFileOperation(
                            path: path,
                            loadAgain: widget.notifier.loadAllContentOfPath,
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
  }
}
