import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Screens/search_screen.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/popup_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class FileExplorerAppBar extends ConsumerWidget {
  const FileExplorerAppBar({super.key, this.initialPath});

  final String? initialPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(
      fileExplorerProvider(initialPath ?? Constant.internalPath),
    );
    final notifier = ref.read(
      fileExplorerProvider(initialPath ?? Constant.internalPath).notifier,
    );

    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);

    final String headingPath = currentState.currentPath == Constant.internalPath
        ? "All Files"
        : p.basename(currentState.currentPath);

    void showAddFolderDialog() {
      addFolderDialog(
        context: context,
        parentPath: currentState.currentPath,
        onSuccess: () =>
            notifier.loadAllContentOfPath(currentState.currentPath),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: IconButton(
            onPressed: () => notifier.goBack(currentState.currentPath, context),
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
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      final names = selectionState.selectedPaths
                          .map((e) => p.basename(e))
                          .toList();
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Do you really want to delete?'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView(
                              shrinkWrap: true,
                              children: names
                                  .map((name) => Text(name))
                                  .toList(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Yes'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        for (final path in selectionState.selectedPaths) {
                          await FileOperations().deleteOperation(path);
                        }
                        selectionNotifier.clearSelection();
                        notifier.loadAllContentOfPath(currentState.currentPath);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea:true,
                        isScrollControlled: true,
                        builder: (context) => BottomSheetForPasteOperation(
                          selectedPaths: Set<String>.from(
                            selectionState.selectedPaths,
                          ),
                          isCopy: true,
                        ),
                      ).then((_) {
                        selectionNotifier.clearSelection();
                        notifier.loadAllContentOfPath(currentState.currentPath);
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.drive_file_move),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea:true,
                        isScrollControlled: true,
                        builder: (context) => BottomSheetForPasteOperation(
                          selectedPaths: Set<String>.from(
                            selectionState.selectedPaths,
                          ),
                          isCopy: false,
                        ),
                      ).then((_) {
                        selectionNotifier.clearSelection();
                        notifier.loadAllContentOfPath(currentState.currentPath);
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: selectionNotifier.clearSelection,
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
                            SearchScreen(Constant.internalPath),
                      );
                    },
                    icon: Icon(Icons.search),
                  ),
                  PopupMenuWidget(
                    showAddFolderDialog: showAddFolderDialog,
                    popupList: ["Create Folder", "Sorting"],
                    currentSortValue: currentState.sortValue,
                    onSortChanged: (value) {
                      notifier.setSortValue(value);
                    },
                  ),
                ],
        ),
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: BreadcrumbWidget(
            path: currentState.currentPath,
            loadContent: notifier.loadAllContentOfPath,
          ),
        ),
      ],
    );
  }
}
