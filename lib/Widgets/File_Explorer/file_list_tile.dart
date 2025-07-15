import 'dart:typed_data';
import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

class FileListTile extends ConsumerStatefulWidget {
  final String path;
  final bool isDrag;

  const FileListTile({super.key, required this.path, this.isDrag = false});

  @override
  ConsumerState<FileListTile> createState() => _FileListTileState();
}

class _FileListTileState extends ConsumerState<FileListTile> {
  Uint8List? _thumbnail;
  Map<String, dynamic>? _metadata;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
    _loadMetadata();
  }

  void _loadThumbnail() async {
    final thumb = await ThumbnailService.getThumbnail(widget.path);
    if (mounted) {
      setState(() {
        _thumbnail = thumb;
      });
    }
  }

  void _loadMetadata() async {
    final meta = await getMetadata(widget.path);
    if (mounted) {
      setState(() {
        _metadata = meta;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = p.basename(widget.path);
    final iconData = MediaUtils.getIconForMedia(
      MediaUtils.getMediaTypeFromExtension(widget.path),
    );
    final isHidden = ref
        .watch(hiddenPathsProvider)
        .hiddenPaths
        .contains(widget.path);
    final selection = ref.watch(selectionProvider);

    return ListTile(
      key: ValueKey(widget.path),
      title: Text(
        fileName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isHidden ? Colors.blueGrey : null),
      ),
      subtitle: _metadata != null
          ? Text(
              "${_metadata!['Size']} | ${_metadata!['Modified']}",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          : const Text("Loading..."),
      leading: _thumbnail != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _thumbnail!,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            )
          : CircleAvatar(child: Icon(iconData)),
      trailing: _buildTrailing(context, selection),
      onTap: () {
        if (selection.isSelectionMode) {
          ref.read(selectionProvider.notifier).toggleSelection(widget.path);
        } else {
          OpenFilex.open(widget.path);
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
            isScrollControlled: true,
            context: context,
            builder: (context) => BottomSheetForSingleFileOperation(
              path: widget.path,
              loadAgain: ref
                  .read(fileExplorerProvider.notifier)
                  .loadAllContentOfPath,
            ),
          );
        },
      );
    }
  }
}
