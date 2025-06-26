import 'package:file_manager/Helpers/sorting_dialog.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/manual_drag_mode_notifier.dart';
import 'package:file_manager/Providers/view_toggle_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingPopupMenuWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == "Sorting") {
          if (onShowSortDialog != null) {
            await onShowSortDialog!();
          }

          String initialSortBy = "name";
          String initialSortOrder = "asc";

          if (currentSortValue != null) {
            if (currentSortValue == "drag") {
              initialSortBy = "drag";
              initialSortOrder = "drag";
            } else if (currentSortValue!.contains("-")) {
              final parts = currentSortValue!.split("-");
              initialSortBy = parts[0];
              initialSortOrder = parts[1];
            }
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

            final sortOrder = result["sortOrder"];
            final sortBy = result["sortBy"];
            final forCurrentPath = result["applyToCurrentPath"] ?? true;

            if (sortOrder == "drag") {
              if (!showPathSpecificOption) return;

              final forCurrentPath = result["applyToCurrentPath"] ?? true;

              if (setSortValue != null) {
                await setSortValue!("drag", forCurrentPath: forCurrentPath);
              } else {
                await ref
                    .read(fileExplorerProvider.notifier)
                    .setSortValue("drag", forCurrentPath: forCurrentPath);
              }
              ref.read(manualDragModeProvider.notifier).state = forCurrentPath;

              final viewModeNotifier = ref.read(fileViewModeProvider.notifier);
              viewModeNotifier.setMode("List View");

              if (onSortChanged != null) {
                onSortChanged!("drag");
              }

              return;
            } else {
              final combinedSort = '$sortBy-$sortOrder';
              if (setSortValue != null) {
                await setSortValue!(
                  combinedSort,
                  forCurrentPath: forCurrentPath,
                );
              }
              if (onSortChanged != null) {
                onSortChanged!(combinedSort);
              }
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
