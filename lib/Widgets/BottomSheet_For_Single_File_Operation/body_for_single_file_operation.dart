import 'dart:io';
import 'package:file_manager/Helpers/rename_dialog.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/get_meta_data.dart';
import 'package:file_manager/Services/sqflite_favorites_db.dart';
import 'package:file_manager/Widgets/bottom_sheet_paste_operation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class BodyForSingleFileOperation extends StatefulWidget {
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
  State<BodyForSingleFileOperation> createState() =>
      _BodyForSingleFileOperationState();
}

class _BodyForSingleFileOperationState
    extends State<BodyForSingleFileOperation> {

  Map<IconData, String> gridList = {
    Icons.copy: "Copy",
    Icons.move_down: "Move",
    Icons.drive_file_rename_outline: "Rename",
    Icons.favorite: "Mark Favorite",
    Icons.delete: "Delete",
    Icons.info_outline: "Details",
  };

  Future<Map<String,dynamic>> getFileDetails(String path) async {
    return await getMetadata(path);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = widget.isChanged == false
        ? gridList.entries.where((e) => e.value != "Copy" && e.value != "Move").toList()
        : gridList.entries.toList();

    return GridView.builder(
      itemCount: filteredEntries.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        return Material(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final action = filteredEntries[index].value;
              switch (action) {
                case "Copy":
                  Navigator.pop(context);
                  showModalBottomSheet(
                    isScrollControlled: true,
                    useSafeArea: true,
                    context: context,
                    builder: (context) => BottomSheetForPasteOperation(
                      isCopy: true,
                      isSingleOperation: true,
                      selectedSinglePath: widget.path,
                    ),
                  ).then((_) {
                    widget.loadAgain(p.dirname(widget.path));
                  });
                  break;
                case "Move":
                  Navigator.pop(context);
                  showModalBottomSheet(
                    isScrollControlled: true,
                    useSafeArea: true,
                    context: context,
                    builder: (context) => BottomSheetForPasteOperation(
                      isCopy: false,
                      isSingleOperation: true,
                      selectedSinglePath: widget.path,
                    ),
                  ).then((_) {
                    widget.loadAgain(p.dirname(widget.path));
                  });
                  break;
                case "Mark Favorite":
                  FavoritesDB()
                      .addFavorite(
                        widget.path,
                        FileSystemEntity.isDirectorySync(widget.path),
                      )
                      .then((_) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Added to Favorites")),
                        );
                        widget.loadAgain(p.dirname(widget.path));
                      });
                  break;
                case "Delete":
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Do you really want to delete ?"),
                      content: Text(p.basename(widget.path)),
                      actions: [
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                          },
                          child: Text("No"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FileOperations().deleteOperation(widget.path);
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                            widget.loadAgain(p.dirname(widget.path));
                          },
                          child: Text("Yes"),
                        ),
                      ],
                    ),
                  );
                  break;
                case "Details":
                  Navigator.pop(context);
                  final data = await getFileDetails(widget.path);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Properties"),
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("Okay"),
                        ),
                      ],
                    ),
                  );
                  break;
                case "Rename":
                  Navigator.pop(context);
                  renameDialogBox(
                    context: context,
                    oldPath: widget.path,
                    onSuccess: () {
                      widget.loadAgain(p.dirname(widget.path));
                    },
                  );
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
                Text(filteredEntries[index].value),
              ],
            ),
          ),
        );
      },
    );
  }
}