import 'dart:io';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/recycler_bin.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

class SelectionActionsWidget extends ConsumerWidget {
  const SelectionActionsWidget({
    super.key,
    required this.onPostAction,
    this.enableShare = false,
  });

  final VoidCallback onPostAction;
  final bool enableShare;

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
            final names = selectionState.selectedPaths.map(p.basename).toList();
            bool deletePermanently = false;
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
                        SizedBox(
                          height: 120,
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: ListView.builder(
                              itemCount: names.length,
                              itemBuilder: (context, index) => Text(
                                "• ${names[index]}",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
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
              if (deletePermanently) {
                for (final path in selectionState.selectedPaths) {
                  await RecentlyDeletedManager().deleteOriginalPath(path);
                }
              } else {
                for (final path in selectionState.selectedPaths) {
                  await FileOperations().deleteOperation(path);
                }
              }
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
          icon: const Icon(Icons.drive_file_move),
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
        if (enableShare && !containsDirectory)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
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
            },
          ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: selectionNotifier.clearSelection,
        ),
      ],
    );
  }
}
