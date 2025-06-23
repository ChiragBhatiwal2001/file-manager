import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:open_filex/open_filex.dart';

class QuickAccessListItem extends StatefulWidget {
  final MediaFile file;
  final dynamic selectionState;
  final dynamic selectionNotifier;
  final Function(String? path) getDataForDisplay;

  const QuickAccessListItem({
    super.key,
    required this.file,
    required this.selectionState,
    required this.selectionNotifier,
    required this.getDataForDisplay,
  });

  @override
  State<QuickAccessListItem> createState() => _QuickAccessListItemState();
}

class _QuickAccessListItemState extends State<QuickAccessListItem> {
  Uint8List? _thumbnail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  void _loadThumbnail() async {
    final thumb = await ThumbnailService.getThumbnail(widget.file.path);
    if (mounted) {
      setState(() {
        _thumbnail = thumb;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split("/").last;

    return ListTile(
      key: ValueKey(widget.file.path),
      leading: _isLoading
          ? const SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : _thumbnail != null
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _thumbnail!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      )
          : CircleAvatar(
        child: Icon(
          MediaUtils.getIconForMedia(widget.file.type),
        ),
      ),
      title: Text(fileName,maxLines: 2,),
      subtitle: FutureBuilder<Map<String, dynamic>>(
        future: getMetadata(widget.file.path), // or folderPath
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Text("Loading...");
          final data = snapshot.data!;
          return Text(
            "${data['Size']} | ${data['Modified']}",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          );
        },
      ),
      trailing: widget.selectionState.isSelectionMode
          ? Checkbox(
        value: widget.selectionState.selectedPaths
            .contains(widget.file.path),
        onChanged: (_) =>
            widget.selectionNotifier.toggleSelection(widget.file.path),
      )
          : IconButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => BottomSheetForSingleFileOperation(
              path: widget.file.path,
              loadAgain: widget.getDataForDisplay,
            ),
          );
        },
        icon: const Icon(Icons.more_vert),
      ),
      onTap: () {
        final isSelectionMode = widget.selectionState.isSelectionMode;
        if (isSelectionMode) {
          widget.selectionNotifier.toggleSelection(widget.file.path);
        } else {
          OpenFilex.open(widget.file.path);
        }
      },
      onLongPress: () {
        widget.selectionNotifier.toggleSelection(widget.file.path);
      },
    );
  }
}
