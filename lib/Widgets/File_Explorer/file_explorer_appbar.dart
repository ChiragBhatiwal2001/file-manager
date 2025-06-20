import 'dart:io';
import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Providers/view_toggle_notifier.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/bottom_sheet_paste_operation.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/search_bottom_sheet.dart';
import 'package:file_manager/Widgets/setting_popup_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileExplorerAppBar extends ConsumerStatefulWidget {
  const FileExplorerAppBar({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<FileExplorerAppBar> createState() {
    return _FileExplorerAppBarState();
  }
}

class _FileExplorerAppBarState extends ConsumerState<FileExplorerAppBar> {
  String _viewMode = "List View";

  @override
  void initState() {
    super.initState();
    getListShowingPreference();
  }

  void getListShowingPreference() async {
    final prefs = await SharedPrefsService.instance;
    setState(() {
      _viewMode = prefs.getString('fileViewGrid') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final fileViewMode = ref.watch(fileViewModeProvider);
    final currentState = ref.watch(
      fileExplorerProvider(widget.initialPath ?? Constant.internalPath),
    );
    final notifier = ref.read(
      fileExplorerProvider(
        widget.initialPath ?? Constant.internalPath,
      ).notifier,
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
                    icon: Icon(Icons.delete, size: 20),
                    onPressed: () async {
                      final names = selectionState.selectedPaths
                          .map((e) => p.basename(e))
                          .toList();
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Delete Permanently?'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: double.maxFinite,
                                  height: 120,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: names
                                        .map((name) => Text(name))
                                        .toList(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
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
                          );
                        },
                      );

                      if (confirmed == true) {
                        await showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            double progress = 0;
                            return StatefulBuilder(
                              builder: (context, setState) {
                                FileOperations()
                                    .deleteMultiple(
                                      selectionState.selectedPaths.toList(),
                                      onProgress: (p) =>
                                          setState(() => progress = p),
                                    )
                                    .then((_) {
                                      Navigator.pop(context);
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Delete Complete'),
                                          content: Text(
                                            'Selected items deleted successfully.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                      selectionNotifier.clearSelection();
                                      notifier.loadAllContentOfPath(
                                        currentState.currentPath,
                                      );
                                    });

                                return AlertDialog(
                                  title: Text('Deleting...'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      LinearProgressIndicator(value: progress),
                                      SizedBox(height: 16),
                                      Text(
                                        '${(progress * 100).toStringAsFixed(0)}%',
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 20),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
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
                    icon: Icon(Icons.drive_file_move, size: 20),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        useSafeArea: true,
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
                  Consumer(
                    builder: (context, ref, _) {
                      final selectionState = ref.watch(selectionProvider);
                      final selectionNotifier = ref.read(
                        selectionProvider.notifier,
                      );

                      final containsFolder = selectionState.selectedPaths.any(
                        (path) => FileSystemEntity.isDirectorySync(path),
                      );

                      return Row(
                        children: [
                          if (!containsFolder)
                            IconButton(
                              icon: Icon(Icons.share, size: 20),
                              onPressed: () async {
                                final filesToShare = selectionState
                                    .selectedPaths
                                    .where((path) {
                                      final file = File(path);
                                      return file.existsSync() &&
                                          file.statSync().type !=
                                              FileSystemEntityType.directory;
                                    })
                                    .toList();

                                if (filesToShare.isNotEmpty) {
                                  final xFiles = filesToShare
                                      .map((e) => XFile(e))
                                      .toList();
                                  await Share.shareXFiles(xFiles);
                                  selectionNotifier.clearSelection();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("No valid files to share."),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20),
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
                            SearchBottomSheet(Constant.internalPath!),
                      );
                    },
                    icon: Icon(Icons.search),
                  ),
                  SettingPopupMenuWidget(
                    popupList: [
                      "Create Folder",
                      "Sorting",
                      fileViewMode == "List View" ? "Grid View" : "List View",
                    ],
                    onViewModeChanged: (mode) async {
                      ref.read(fileViewModeProvider.notifier).setMode(mode);
                    },
                    currentPath: currentState.currentPath,
                    currentSortValue: ref
                        .watch(fileExplorerProvider(currentState.currentPath))
                        .sortValue,
                    setSortValue: (sortValue, {forCurrentPath = false}) {
                      return ref
                          .read(
                            fileExplorerProvider(
                              currentState.currentPath,
                            ).notifier,
                          )
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
            path: currentState.currentPath,
            loadContent: notifier.loadAllContentOfPath,
          ),
        ),
      ],
    );
  }
}
