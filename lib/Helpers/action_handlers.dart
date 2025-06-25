import 'dart:io';
import 'package:file_manager/Helpers/detail_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:file_manager/Providers/favorite_notifier.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/recycler_bin.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Helpers/rename_dialog.dart';

Future<void> handleAction({
  required BuildContext context,
  required WidgetRef ref,
  required String action,
  required String path,
  required bool isFavorite,
  required void Function(String path) loadAgain,
}) async {
  switch (action) {
    case "Copy":
      Navigator.pop(context);
      await _showPasteSheet(context, true, path, loadAgain);
      break;
    case "Move":
      Navigator.pop(context);
      await _showPasteSheet(context, false, path, loadAgain);
      break;
    case "Mark Favorite":
      Navigator.pop(context);
      await _toggleFavorite(context, ref, path, isFavorite, loadAgain);
      break;
    case "Remove Favorite":
      Navigator.pop(context);
      await _toggleFavorite(context, ref, path, isFavorite, loadAgain);
      break;
    case "Delete":
      await _handleDelete(context, path, loadAgain);
      break;
    case "Details":
      Navigator.pop(context);
      await showDetailsDialog(context, path);
      break;
    case "Rename":
      Navigator.pop(context);
      await handleRename(context, path, loadAgain);
      break;
    default:
      Navigator.pop(context);
      break;
  }
}

Future<void> _showPasteSheet(
  BuildContext context,
  bool isCopy,
  String path,
  void Function(String) loadAgain,
) async {
  try {
    final result = await showModalBottomSheet<bool>(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      builder: (context) => BottomSheetForPasteOperation(
        isCopy: isCopy,
        isSingleOperation: true,
        selectedSinglePath: path,
      ),
    );
    if (result == true) loadAgain(p.dirname(path));
  } catch (_) {
    await showErrorDialog(
      context,
      "${isCopy ? "Copy" : "Move"} operation failed.",
    );
  }
}

Future<void> _toggleFavorite(
  BuildContext context,
  WidgetRef ref,
  String path,
  bool isFavorite,
  void Function(String path) loadAgain,
) async {
  try {
    await ref
        .read(favoritesProvider.notifier)
        .toggleFavorite(path, FileSystemEntity.isDirectorySync(path));

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Favorites"),
        content: Text(
          isFavorite ? "Removed from Favorites" : "Added to Favorites",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    loadAgain(p.dirname(path));
  } catch (e) {
    await showErrorDialog(context, "Favorite operation failed.\n$e");
  }
}

Future<void> _handleDelete(
  BuildContext context,
  String path,
  void Function(String) loadAgain,
) async {
  bool deletePermanently = false;
  try {
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Do you really want to delete?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${p.basename(path)} will be deleted from this device."),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text("Delete permanently"),
                value: deletePermanently,
                onChanged: (val) =>
                    setState(() => deletePermanently = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  if (deletePermanently) {
                    await RecentlyDeletedManager().deleteOriginalPath(path);
                  } else {
                    await FileOperations().deleteOperation(path);
                  }
                  if (context.mounted) {
                    // Close progress dialog first (if it's still open)
                    Navigator.of(
                      Navigator.of(context).context,
                      rootNavigator: true,
                    ).pop();
                  }
                  loadAgain(p.dirname(path));
                } catch (_) {
                  await showErrorDialog(context, "Delete operation failed.");
                }
              },
              child: const Text("Yes"),
            ),
          ],
        ),
      ),
    );
  } catch (_) {
    await showErrorDialog(context, "Delete operation failed.");
  }
}

Future<void> handleRename(
  BuildContext context,
  String path,
  void Function(String) loadAgain,
) async {
  try {
    await renameDialogBox(
      context: context,
      oldPath: path,
      onSuccess: () {
        loadAgain(p.dirname(path));
      },
    );

    // Close the previous bottom sheet/dialog safely
    if (context.mounted) Navigator.pop(context);
  } catch (_) {
    await showErrorDialog(context, "Rename operation failed.");
  }
}
