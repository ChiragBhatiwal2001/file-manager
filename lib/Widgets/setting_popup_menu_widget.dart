import 'package:file_manager/Helpers/sorting_dialog.dart';
import 'package:flutter/material.dart';

class SettingPopupMenuWidget extends StatelessWidget {
  final List<String> popupList;
  final VoidCallback? showAddFolderDialog;
  final void Function(String sortValue)? onSortChanged;
  final String? currentSortValue;
  final String? currentPath;
  final Future<void> Function(String sortValue, {bool forCurrentPath})?
  setSortValue;
  final Future<void> Function()? onShowSortDialog;
  final bool showPathSpecificOption;
  final void Function(String viewMode)? onViewModeChanged;

  const SettingPopupMenuWidget({
    super.key,
    required this.popupList,
    required this.currentSortValue,
    this.showAddFolderDialog,
    this.onSortChanged,
    this.onViewModeChanged,
    this.currentPath,
    this.onShowSortDialog,
    this.setSortValue,
    this.showPathSpecificOption = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == "Sorting") {
          if (onShowSortDialog != null) {
            await onShowSortDialog!();
          }

          String initialSortBy = "name";
          String initialSortOrder = "asc";

          if (currentSortValue != null && currentSortValue!.contains("-")) {
            final parts = currentSortValue!.split("-");
            initialSortBy = parts[0];
            initialSortOrder = parts[1];
          }

          await showDialog(
            context: context,
            builder: (context) => SortDialog(
              initialSortBy: initialSortBy,
              initialSortOrder: initialSortOrder,
              showPathSpecificOption: showPathSpecificOption,
            ),
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
        } else if (value == "List View" || value == "Grid View") {
          if (onViewModeChanged != null) {
            onViewModeChanged!(value);
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
