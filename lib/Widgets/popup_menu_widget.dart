import 'package:flutter/material.dart';

class PopupMenuWidget extends StatelessWidget {
  final List<String> popupList;
  final VoidCallback? showAddFolderDialog;
  final void Function(String sortValue)? onSortChanged;
  final String? currentSortValue;
  final String? currentPath;
  final Future<void> Function(String sortValue, {bool forCurrentPath})?
  setSortValue;
  final bool showPathSpecificOption;

  const PopupMenuWidget({
    super.key,
    required this.popupList,
    this.showAddFolderDialog,
    this.onSortChanged,
    required this.currentSortValue,
    this.currentPath,
    this.setSortValue,
    this.showPathSpecificOption = false, // default is false
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
              bool _applyToCurrentPath = false;

              return StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: const Text("Sort By"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile(
                        title: const Text("Name"),
                        value: "name",
                        groupValue: _sortBy,
                        onChanged: (val) =>
                            setState(() => _sortBy = val as String),
                      ),
                      RadioListTile(
                        title: const Text("Size"),
                        value: "size",
                        groupValue: _sortBy,
                        onChanged: (val) =>
                            setState(() => _sortBy = val as String),
                      ),
                      RadioListTile(
                        title: const Text("Last Modified"),
                        value: "modified",
                        groupValue: _sortBy,
                        onChanged: (val) =>
                            setState(() => _sortBy = val as String),
                      ),
                      if (showPathSpecificOption)
                        SwitchListTile(
                          title: const Text("only this folder"),
                          value: _applyToCurrentPath,
                          onChanged: (val) =>
                              setState(() => _applyToCurrentPath = val),
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
                                "applyToCurrentPath": _applyToCurrentPath,
                              });
                            },
                            child: const Text("Descending"),
                          ),
                          TextButton(
                            onPressed: () {
                              _sortOrder = "asc";
                              Navigator.pop(context, {
                                "sortBy": _sortBy,
                                "sortOrder": _sortOrder,
                                "applyToCurrentPath": _applyToCurrentPath,
                              });
                            },
                            child: const Text("Ascending"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ).then((result) async {
            if (result == null) return;

            final combinedSort = '${result["sortBy"]}-${result["sortOrder"]}';
            final bool forCurrentPath = result["applyToCurrentPath"] ?? true;

            if (setSortValue != null) {
              await setSortValue!(combinedSort, forCurrentPath: forCurrentPath);
            }
            if (onSortChanged != null) {
              onSortChanged!(combinedSort);
            }
          });
        } else if (value == "Create Folder") {
          if (showAddFolderDialog != null) {
            showAddFolderDialog!();
          }
        }
      },
      icon: const Icon(Icons.more_vert_sharp),
      itemBuilder: (context) => popupList.map((item) {
        return PopupMenuItem(value: item, child: Text(item));
      }).toList(),
    );
  }
}
