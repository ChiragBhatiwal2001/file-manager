import 'dart:io';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/show_progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

class SelectionActionsWidget extends ConsumerWidget {
  const SelectionActionsWidget({
    super.key,
    required this.onPostAction,
    this.enableShare = false,
    required this.allCurrentPaths,
  });

  final VoidCallback onPostAction;
  final bool enableShare;
  final List<String> allCurrentPaths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);

    final containsDirectory = selectionState.selectedPaths.any((path) {
      final file = FileSystemEntity.typeSync(path);
      return file == FileSystemEntityType.directory;
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            bool deletePermanently = false;
            final selectedPaths = selectionState.selectedPaths;
            final isSingle = selectedPaths.length == 1;
            final contentMessage = isSingle
                ? '${p.basename(selectedPaths.first)} will be deleted from this device.'
                : '${selectedPaths.length} items will be deleted from this device.';

            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) {
                return StatefulBuilder(
                  builder: (context, setState) => AlertDialog(
                    title: const Text('Delete Selected Items?'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(contentMessage),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          title: const Text("Delete permanently"),
                          value: deletePermanently,
                          onChanged: (val) =>
                              setState(() => deletePermanently = val ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
            );
            if (confirmed == true) {
              await showProgressDialog(
                context: context,
                operation: (onProgress) async {
                  final fileOps = FileOperations();
                  if (deletePermanently) {
                    await fileOps.deleteMultiplePermanently(
                      selectedPaths.toList(),
                      onProgress: onProgress,
                    );
                  } else {
                    await fileOps.deleteMultiple(
                      selectedPaths.toList(),
                      onProgress: onProgress,
                    );
                  }
                },
              );

              selectionNotifier.clearSelection();
              onPostAction();
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (context) => BottomSheetForPasteOperation(
                selectedPaths: {...selectionState.selectedPaths},
                isCopy: true,
              ),
            ).then((_) {
              selectionNotifier.clearSelection();
              onPostAction();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.cut),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              builder: (context) => BottomSheetForPasteOperation(
                selectedPaths: {...selectionState.selectedPaths},
                isCopy: false,
              ),
            ).then((_) {
              selectionNotifier.clearSelection();
              onPostAction();
            });
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'share':
                final files = selectionState.selectedPaths
                    .where((path) {
                  final file = File(path);
                  return file.existsSync() &&
                      file.statSync().type != FileSystemEntityType.directory;
                })
                    .map((path) => XFile(path))
                    .toList();

                if (files.isNotEmpty) {
                  final params = ShareParams(files: files);
                  final result = await SharePlus.instance.share(params);
                  if (result.status == ShareResultStatus.success) {
                    selectionNotifier.clearSelection();
                  } else if (result.status == ShareResultStatus.dismissed) {
                    debugPrint('User dismissed the share sheet.');
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No valid files to share.")),
                  );
                }
                break;
              case 'select_all':
                selectionNotifier.selectAll(allCurrentPaths);
                break;
              case 'close':
                selectionNotifier.clearSelection();
                break;
            }
          },
          itemBuilder: (context) => [
            if (enableShare && !containsDirectory)
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                ),
              ),
            const PopupMenuItem(
              value: 'select_all',
              child: ListTile(
                leading: Icon(Icons.select_all),
                title: Text('Select All'),
              ),
            ),
            const PopupMenuItem(
              value: 'close',
              child: ListTile(
                leading: Icon(Icons.close),
                title: Text('Clear Selection'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
