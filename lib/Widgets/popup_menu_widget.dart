import 'package:flutter/material.dart';

class PopupMenuWidget extends StatelessWidget {
  final List<String> popupList;
  final void Function() addContent;
  final void Function(String sortValue)? onSortChanged;
  final String? currentSortValue;

  const PopupMenuWidget({
    super.key,
    required this.popupList,
    required this.addContent,
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
                builder: (context, setState) =>
                    AlertDialog(
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
        } else if (value == "Create Folder") { // <-- Handle create folder
          addContent();
        }
      },
      icon: Icon(Icons.more_vert_sharp),
      itemBuilder: (context) =>
          popupList.map((item) {
            return PopupMenuItem(value: item, child: Text(item));
          }).toList(),
    );
  }
}