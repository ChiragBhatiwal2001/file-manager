import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
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
  const FileExplorerAppBar({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<FileExplorerAppBar> createState() {
    return _FileExplorerAppBarState();
  }
}

class _FileExplorerAppBarState extends ConsumerState<FileExplorerAppBar> {

  @override
  Widget build(BuildContext context) {
    final fileViewMode = ref.watch(fileViewModeProvider);
    final currentPath = ref.watch(currentPathProvider);

    final currentState = ref.watch(fileExplorerProvider(currentPath));
    final notifier = ref.read(fileExplorerProvider(currentPath).notifier);

    final allCurrentPaths = [
      ...currentState.folders.map((e) => e.path),
      ...currentState.files.map((e) => e.path),
    ];

    final selectionState = ref.watch(selectionProvider);

    final String headingPath = currentPath == Constant.internalPath
        ? "All Files"
        : p.basename(currentPath);

    void showAddFolderDialog() {
      addFolderDialog(
        context: context,
        parentPath: currentPath,
        onSuccess: () => notifier.loadAllContentOfPath(currentPath),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: IconButton(
            onPressed: () => notifier.goBack(context, ref),
            icon: const Icon(Icons.arrow_back),
          ),
          titleSpacing: 0,
          title: Text(
            headingPath,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 2,
          actions: selectionState.isSelectionMode
              ? [
            SelectionActionsWidget(
              onPostAction: () =>
                  notifier.loadAllContentOfPath(currentPath),
              allCurrentPaths: allCurrentPaths,
              enableShare: true,
            )
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
              currentPath: currentPath,
              currentSortValue:
              ref.watch(fileExplorerProvider(currentPath)).sortValue,
              setSortValue: (sortValue, {forCurrentPath = false}) {
                return ref
                    .read(fileExplorerProvider(currentPath).notifier)
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
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: BreadcrumbWidget(
            path: currentPath,
            loadContent: notifier.loadAllContentOfPath,
          ),
        ),
      ],
    );
  }
}