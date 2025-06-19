import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Services/media_scanner.dart';
import 'package:file_manager/Utils/MediaUtils.dart';
import 'package:file_manager/Services/thumbnail_service.dart';
import 'package:open_filex/open_filex.dart';

class QuickAccessListItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final fileName = file.path.split("/").last;
    return ListTile(
      key: ValueKey(file.path),
      leading: FutureBuilder<Uint8List?>(
        future: ThumbnailService.getSmartThumbnail(file.path),
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
            return CircleAvatar(
              child: Icon(MediaUtils.getIconForMedia(file.type)),
            );
          }
        },
      ),
      title: Text(fileName),
      trailing: selectionState.isSelectionMode
          ? Checkbox(
              value: selectionState.selectedPaths.contains(file.path),
              onChanged: (_) => selectionNotifier.toggleSelection(file.path),
            )
          : IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => BottomSheetForSingleFileOperation(
                    path: file.path,
                    loadAgain: getDataForDisplay,
                  ),
                );
              },
              icon: Icon(Icons.more_vert),
            ),
      onTap: () {
        final isSelectionMode = selectionState.isSelectionMode;
        if (isSelectionMode) {
          selectionNotifier.toggleSelection(file.path);
        } else {
          OpenFilex.open(file.path);
        }
      },
      onLongPress: () {
        selectionNotifier.toggleSelection(file.path);
      },
    );
  }
}
