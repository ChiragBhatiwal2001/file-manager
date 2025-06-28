import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/manual_drag_mode_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Providers/view_toggle_notifier.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/Common_Appbar/common_appbar_actions.dart';
import 'package:file_manager/Widgets/Search_Bottom_Sheet/search_bottom_sheet.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/setting_popup_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class FileExplorerAppBar extends ConsumerStatefulWidget {
  final String currentPath;

  const FileExplorerAppBar({super.key, required this.currentPath});

  @override
  ConsumerState<FileExplorerAppBar> createState() {
    return _FileExplorerAppBarState();
  }
}

class _FileExplorerAppBarState extends ConsumerState<FileExplorerAppBar> {
  @override
  Widget build(BuildContext context) {
    final fileViewMode = ref.watch(fileViewModeProvider);
    final isDragMode = ref.watch(manualDragModeProvider);
    final currentState = ref.watch(fileExplorerProvider);

    final allCurrentPaths = [
      ...currentState.folders.map((e) => e.path),
      ...currentState.files.map((e) => e.path),
    ];

    final selectionState = ref.watch(selectionProvider);

    String headingPath = currentState.currentPath == Constant.internalPath
        ? "All Files"
        : p.basename(currentState.currentPath);

    void showAddFolderDialog() {
      addFolderDialog(
        context: context,
        parentPath: widget.currentPath,
        onSuccess: () {
          if (!mounted) return;
          final freshNotifier = ref.read(fileExplorerProvider.notifier);
          if (freshNotifier.mounted) {
            freshNotifier.loadAllContentOfPath(widget.currentPath);
          }
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: isDragMode
              ? const SizedBox.shrink()
              : IconButton(
            onPressed: () {
              final selectionNotifier = ref.read(selectionProvider.notifier);

              if (selectionState.isSelectionMode) {
                selectionNotifier.clearSelection();
                return;
              }

              final currentPath = ref.read(fileExplorerProvider).currentPath;
              final rootPath = widget.currentPath;

              if (currentPath == rootPath) {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(); // Exit screen
                }
              } else {
                ref.read(fileExplorerProvider.notifier).goBack(context); // Navigate up
              }
            },
            icon: Icon(
              selectionState.isSelectionMode
                  ? Icons.close
                  : Icons.arrow_back,
            ),
          ),
          titleSpacing: 0,
          title: Text(
            selectionState.isSelectionMode
                ? "${selectionState.selectedPaths.length} selected"
                : headingPath,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 2,
          actions: isDragMode
              ? null
              : selectionState.isSelectionMode
              ? [
                  SelectionActionsWidget(
                    onPostAction: (String? path) {
                      if (!mounted) return;
                      final pathToLoad = path ?? widget.currentPath;

                      final freshNotifier = ref.read(fileExplorerProvider.notifier);
                      if (freshNotifier.mounted) {
                        freshNotifier.loadAllContentOfPath(pathToLoad);
                      }
                    },
                    allCurrentPaths: allCurrentPaths,
                    enableShare: true,
                  ),
                ]
              : [
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        builder: (context) =>
                            SearchBottomSheet(Constant.internalPath!),
                      );
                    },
                    icon: const Icon(Icons.search),
                  ),
                  SettingPopupMenuWidget(
                    popupList: [
                      "Create Folder",
                      "Sorting",
                      fileViewMode == "List View" ? "Grid View" : "List View",
                    ],
                    onViewModeChanged: (mode) {
                      ref.read(fileViewModeProvider.notifier).setMode(mode);
                    },
                    currentPath: currentState.currentPath,
                    currentSortValue: currentState.sortValue,
                    setSortValue: (sortValue, {forCurrentPath = false}) {
                      return ref
                          .read(fileExplorerProvider.notifier)
                          .setSortValue(
                            sortValue,
                            forCurrentPath: forCurrentPath,
                          );
                    },
                    showAddFolderDialog: showAddFolderDialog,
                    showPathSpecificOption: true,
                  ),
                ],
        ),
        if (!isDragMode)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: BreadcrumbWidget(
              path: currentState.currentPath,
              currentPath: currentState.currentPath,
              loadContent: (path) {
                final freshNotifier = ref.read(fileExplorerProvider.notifier);
                if (freshNotifier.mounted) {
                  freshNotifier.loadAllContentOfPath(path);
                }
              },
            ),
          ),
      ],
    );
  }
}
