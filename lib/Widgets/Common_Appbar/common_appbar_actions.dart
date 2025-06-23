import 'dart:io';
import 'package:file_manager/Services/file_operations.dart';
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () async {
            final names = selectionState.selectedPaths.map(p.basename).toList();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Selected Items?'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 150,
                  child: ListView(children: names.map(Text.new).toList()),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                ],
              ),
            );
            if (confirmed == true) {
              for (final path in selectionState.selectedPaths) {
                await FileOperations().deleteOperation(path);
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
        if (enableShare)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final files = selectionState.selectedPaths
                  .where((path) {
                final file = File(path);
                return file.existsSync() && file.statSync().type != FileSystemEntityType.directory;
              })
                  .map((e) => XFile(e))
                  .toList();

              if (files.isNotEmpty) {
                await Share.shareXFiles(files);
                selectionNotifier.clearSelection();
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
