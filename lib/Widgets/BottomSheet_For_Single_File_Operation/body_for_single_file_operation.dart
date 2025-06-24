import 'dart:io';
import 'package:file_manager/Helpers/rename_dialog.dart';
import 'package:file_manager/Providers/favorite_notifier.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Services/recycler_bin.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/bottom_sheet_paste_operation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class BodyForSingleFileOperation extends ConsumerStatefulWidget {
  const BodyForSingleFileOperation({
    super.key,
    required this.path,
    required this.loadAgain,
    required this.isChanged,
  });

  final String path;
  final void Function(String path) loadAgain;
  final bool isChanged;

  @override
  ConsumerState<BodyForSingleFileOperation> createState() =>
      _BodyForSingleFileOperationState();
}

class _BodyForSingleFileOperationState
    extends ConsumerState<BodyForSingleFileOperation> {
  final Map<IconData, String> gridList = {
    Icons.copy: "Copy",
    Icons.move_down: "Move",
    Icons.drive_file_rename_outline: "Rename",
    Icons.favorite: "Favorite",
    Icons.delete: "Delete",
    Icons.info_outline: "Details",
  };

  Future<Map<String, dynamic>> getFileDetails(String path) async =>
      await getMetadata(path);

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    ),
  );

  Future<void> _showErrorDialog(BuildContext context, String msg) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Operation Failed"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _showPasteSheet(BuildContext context, bool isCopy) async {
    try {
      final resultPath = await showModalBottomSheet<String>(
        isScrollControlled: true,
        useSafeArea: true,
        context: context,
        builder: (context) => BottomSheetForPasteOperation(
          isCopy: isCopy,
          isSingleOperation: true,
          selectedSinglePath: widget.path,
        ),
      );

      if (resultPath != null && resultPath != widget.path) {

        double progress = 0.0;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => StatefulBuilder(
            builder: (context, setState) {
              // Start the file operation
              FileOperations()
                  .pasteFileToDestination(
                isCopy,
                resultPath,
                widget.path,
                onProgress: (val) {
                  setState(() => progress = val);
                },
              )
                  .then((_) async {
                if (context.mounted) {
                  Navigator.pop(context);
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Success"),
                      content: Text(isCopy
                          ? "File copied successfully."
                          : "File moved successfully."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                }
                widget.loadAgain(p.dirname(widget.path));
              }).catchError((e) async {
                if (context.mounted) {
                  Navigator.pop(context);
                  await _showErrorDialog(
                      context, "${isCopy ? "Copy" : "Move"} failed.\n$e");
                }
              });

              return AlertDialog(
                title: Text(isCopy ? "Copying..." : "Moving..."),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 12),
                    Text("${(progress * 100).toStringAsFixed(1)}%"),
                  ],
                ),
              );
            },
          ),
        );
      }
    } catch (e) {
      await _showErrorDialog(
        context,
        "${isCopy ? "Copy" : "Move"} operation failed.",
      );
    }
  }


  Future<void> _toggleFavorite(BuildContext context, bool isFavorite) async {
    Navigator.pop(context);
    try {
      await ref
          .read(favoritesProvider.notifier)
          .toggleFavorite(
            widget.path,
            FileSystemEntity.isDirectorySync(widget.path),
          );
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Favorites"),
            content: Text(
              isFavorite ? "Removed from Favorites" : "Added to Favorites",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text("Ok"),
              ),
            ],
          ),
        );
      }
      widget.loadAgain(p.dirname(widget.path));
    } catch (e) {
      await _showErrorDialog(context, "Favorite operation failed.\n$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(widget.path);

    final filteredEntries = widget.isChanged
        ? gridList.entries
              .map(
                (e) => MapEntry(
                  e.key,
                  e.value == "Favorite"
                      ? (isFavorite ? "Remove Favorite" : "Mark Favorite")
                      : e.value,
                ),
              )
              .toList()
        : gridList.entries
              .where((e) => e.value != "Copy" && e.value != "Move")
              .toList();

    return GridView.builder(
      itemCount: filteredEntries.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        final action = filteredEntries[index].value;

        return Material(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              switch (action) {
                case "Copy":
                  Navigator.pop(context);
                  await _showPasteSheet(context, true);
                  break;
                case "Move":
                  Navigator.pop(context);
                  await _showPasteSheet(context, false);
                  break;
                case "Mark Favorite":
                  await _toggleFavorite(context, isFavorite);
                  break;
                case "Remove Favorite":
                  await _toggleFavorite(context, isFavorite);
                  break;
                case "Delete":
                  await _handleDelete(context);
                  break;
                case "Details":
                  await _showDetails(context);
                  break;
                case "Rename":
                  Navigator.pop(context);
                  await _handleRename(context);
                  break;
                default:
                  Navigator.pop(context);
                  break;
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(child: Icon(filteredEntries[index].key)),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    filteredEntries[index].value,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    bool deletePermanently = false;
    try {
      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Do you really want to delete?"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.basename(widget.path)),
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
                onPressed: () => Navigator.pop(context),
                child: const Text("No"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    if (deletePermanently) {
                      await RecentlyDeletedManager().deleteOriginalPath(
                        widget.path,
                      );
                    } else {
                      await FileOperations().deleteOperation(widget.path);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text("Successfully Deleted"),
                          content: const Text("Item deleted successfully"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                    }

                    widget.loadAgain(p.dirname(widget.path));
                  } catch (e) {
                    await _showErrorDialog(context, "Delete operation failed.");
                  }
                },
                child: const Text("Yes"),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      await _showErrorDialog(context, "Delete operation failed.");
    }
  }

  Future<void> _showDetails(BuildContext context) async {
    Navigator.pop(context);
    final data = await getFileDetails(widget.path);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Properties"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow("Name", data["Name"]),
            _detailRow("Path", data["Path"]),
            _detailRow("Type", data["Type"]),
            _detailRow("Last Modified", data["Modified"]),
            _detailRow("Size", data["Size"]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Okay"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRename(BuildContext context) async {
    try {
      await renameDialogBox(
        context: context,
        oldPath: widget.path,
        onSuccess: () {
          widget.loadAgain(p.dirname(widget.path));
        },
      );
    } catch (e) {
      await _showErrorDialog(context, "Rename operation failed.");
    }
  }
}
