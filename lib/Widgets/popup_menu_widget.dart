import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:flutter/material.dart';

class PopupMenuWidget extends StatelessWidget {
  final List<String> popupList;
  final VoidCallback? showAddFolderDialog;
  final void Function(String sortValue)? onSortChanged;
  final String? currentSortValue;

  PopupMenuWidget({
    super.key,
    this.showAddFolderDialog,
    required this.popupList,
    this.onSortChanged,
    this.currentSortValue,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == "Sorting") {
          String initialSortBy = "name";
          String initialSortOrder = "asc";
          if (currentSortValue != null && currentSortValue!.contains("-")) {
            final parts = currentSortValue!.split("-");
            initialSortBy = parts[0];
            initialSortOrder = parts[1];
          }
          await showDialog(
            context: context,
            builder: (context) {
              String _sortBy = initialSortBy;
              String _sortOrder = initialSortOrder;
              return StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: Text("Sort By"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile(
                        title: Text("Name"),
                        value: "name",
                        groupValue: _sortBy,
                        onChanged: (val) {
                          setState(() => _sortBy = val as String);
                        },
                      ),
                      RadioListTile(
                        title: Text("Size"),
                        value: "size",
                        groupValue: _sortBy,
                        onChanged: (val) {
                          setState(() => _sortBy = val as String);
                        },
                      ),
                      RadioListTile(
                        title: Text("Last Modified"),
                        value: "modified",
                        groupValue: _sortBy,
                        onChanged: (val) {
                          setState(() => _sortBy = val as String);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              _sortOrder = "desc";
                              Navigator.pop(context, {
                                "sortBy": _sortBy,
                                "sortOrder": _sortOrder,
                              });
                            },
                            child: Text("Descending"),
                          ),
                          TextButton(
                            onPressed: () {
                              _sortOrder = "asc";
                              Navigator.pop(context, {
                                "sortBy": _sortBy,
                                "sortOrder": _sortOrder,
                              });
                            },
                            child: Text("Ascending"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ).then((result) {
            if (result != null && onSortChanged != null) {
              onSortChanged!('${result["sortBy"]}-${result["sortOrder"]}');
            }
          });
        } else if (value == "Create Folder") {
          if (showAddFolderDialog != null) {
            showAddFolderDialog!();
          }
        }
      },
      icon: Icon(Icons.more_vert_sharp),
      itemBuilder: (context) => popupList.map((item) {
        return PopupMenuItem(value: item, child: Text(item));
      }).toList(),
    );
  }
}
