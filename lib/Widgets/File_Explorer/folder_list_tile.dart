import 'package:file_manager/Providers/folder_meta_deta_provider.dart';
import 'package:file_manager/Providers/hide_file_folder_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/file_explorer_state_model.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Widgets/BottomSheet_For_Single_File_Operation/bottom_sheet_single_file_operations.dart';
import 'package:path/path.dart' as p;

class FolderListTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = ref.watch(hiddenPathsProvider).hiddenPaths.contains(path);
    final folderName = p.basename(path);
    final notifier = ref.read(providerInstance.notifier);
    final metadata = ref.watch(folderMetadataProvider(path));

    return ListTile(
      key: ValueKey(path),
      title: Text(
        folderName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isHidden ? Colors.blueGrey : null),
      ),
      subtitle: metadata.when(
        data: (data) => Text(
          "${data['Size']} | ${data['Modified']}",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        loading: () => const Text("Loading...", style: TextStyle(fontSize: 12)),
        error: (_, __) => const Text("Error", style: TextStyle(fontSize: 12)),
      ),
      leading: CircleAvatar(
        child: Icon(Icons.folder, color: isHidden ? Colors.grey : null),
      ),
      trailing: _buildTrailing(context, ref),
      onTap: () {
        final selection = ref.read(selectionProvider);
        if (selection.isSelectionMode) {
          ref.read(selectionProvider.notifier).toggleSelection(path);
        } else {
          notifier.loadAllContentOfPath(path);
        }
      },
      onLongPress: () {
        if (isDrag == false) {
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
              loadAgain: ref
                  .read(providerInstance.notifier)
                  .loadAllContentOfPath,
            ),
          );
        },
      );
    }
  }
}
