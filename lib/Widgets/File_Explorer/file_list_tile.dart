import 'dart:typed_data';
import 'package:file_manager/Providers/folder_meta_deta_provider.dart';
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

class FileListTile extends ConsumerWidget {
  final String path;
  final StateNotifierProvider<FileExplorerNotifier, FileExplorerState> providerInstance;
  final bool isDrag;

  const FileListTile({super.key, required this.path, required this.providerInstance,this.isDrag = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileName = p.basename(path);
    final iconData = MediaUtils.getIconForMedia(
      MediaUtils.getMediaTypeFromExtension(path),
    );
    final metadata = ref.watch(folderMetadataProvider(path));

    return ListTile(
      key: ValueKey(path),
      title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: metadata.when(
        data: (data) => Text(
          "${data['Size']} | ${data['Modified']}",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        loading: () => const Text("Loading...", style: TextStyle(fontSize: 12)),
        error: (_, __) => const Text("Error", style: TextStyle(fontSize: 12)),
      ),
      leading: FutureBuilder<Uint8List?>(
        future: ThumbnailService.getThumbnail(path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(snapshot.data!, width: 40, height: 40, fit: BoxFit.cover),
            );
          } else {
            return CircleAvatar(child: Icon(iconData));
          }
        },
      ),
      trailing: _buildTrailing(context, ref),
      onTap: () {
        final selection = ref.read(selectionProvider);
        if (selection.isSelectionMode) {
          ref.read(selectionProvider.notifier).toggleSelection(path);
        } else {
          OpenFilex.open(path);
        }
      },
      onLongPress: () {
        if(isDrag == false){
          ref.read(selectionProvider.notifier).toggleSelection(path);
        }
      },
    );
  }

  Widget _buildTrailing(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(selectionProvider);
    final notifier = ref.read(selectionProvider.notifier);

    if (selection.isSelectionMode) {
      return Checkbox(
        value: selection.selectedPaths.contains(path),
        onChanged: (_) => notifier.toggleSelection(path),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => BottomSheetForSingleFileOperation(
              path: path,
              loadAgain: ref.read(providerInstance.notifier).loadAllContentOfPath,
            ),
          );
        },
      );
    }
  }
}
