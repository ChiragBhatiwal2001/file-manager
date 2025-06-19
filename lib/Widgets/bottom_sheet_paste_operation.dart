import 'dart:io';
import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/path_loading_operations.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BottomSheetForPasteOperation extends StatefulWidget {
  const BottomSheetForPasteOperation({
    super.key,
    this.selectedPaths,
    this.selectedSinglePath,
    required this.isCopy,
    this.isSingleOperation = false,
  });

  final Set<String>? selectedPaths;
  final String? selectedSinglePath;
  final bool isCopy;
  final bool isSingleOperation;

  @override
  State<BottomSheetForPasteOperation> createState() =>
      _BottomSheetForPasteOperationState();
}

class _BottomSheetForPasteOperationState
    extends State<BottomSheetForPasteOperation> {
  late String currentPath;
  bool isLoading = false;
  List<FileSystemEntity> folderData = [];
  List<FileSystemEntity> fileData = [];

  @override
  void initState() {
    super.initState();
    currentPath = Constant.internalPath;
    loadAllContentOfPath(currentPath);
  }

  Future<void> loadAllContentOfPath(String path) async {
    setState(() => isLoading = true);
    final data = await compute<String, DirectoryContent>(
      PathLoadingOperations.loadContentIsolate,
      path,
    );
    setState(() {
      currentPath = path;
      folderData = data.folders;
      fileData = data.files;
      isLoading = false;
    });
  }

  void goBack(String path) async {
    final data = await PathLoadingOperations.goBackToParentPath(context, path);
    if (data == null) return;
    setState(() {
      currentPath = Directory(path).parent.path;
      folderData = data.folders;
      fileData = data.files;
    });
  }

  Future<bool> _showProgressDialog(
      BuildContext context,
      Future<void> Function(void Function(double)) operation,
      ) async {
    double progress = 0.0;
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        late void Function(void Function()) localSetState;

        operation((value) {
          progress = value;
          if (localSetState != null) {
            localSetState(() {});
          }
        }).then((_) {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        }).catchError((e) {
          error = e.toString();
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return StatefulBuilder(
          builder: (context, setState) {
            localSetState = setState;
            return AlertDialog(
              title: const Text("Processing..."),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 16),
                  Text("${(progress * 100).toStringAsFixed(0)}%"),
                ],
              ),
            );
          },
        );
      },
    );

    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text(error != null
            ? "Operation Failed"
            : "Operation Finished Successfully"),
        content: error != null ? Text(error!) : null,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("OK"),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = folderData.isEmpty && fileData.isEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1,
      builder: (context, scrollController) {
        if (isLoading) return const Center(child: CircularProgressIndicator());

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => goBack(currentPath),
                  child: const Text("Back", style: TextStyle(fontSize: 16)),
                ),
                const Spacer(),
                Text(
                  "${currentPath.split("/").last == "0" ? "All Files" : currentPath.split("/").last}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    addFolderDialog(
                      context: context,
                      parentPath: currentPath,
                      onSuccess: () => loadAllContentOfPath(currentPath),
                    );
                  },
                  child: const Text("Create", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            BreadcrumbWidget(
              path: Constant.internalPath,
              loadContent: loadAllContentOfPath,
            ),
            isEmpty
                ? const Expanded(child: ScreenEmptyWidget())
                : Expanded(
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  if (folderData.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(left: 12, top: 8),
                        child: Text(
                          "Folders",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigoAccent,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final folder = folderData[index];
                          final folderName = folder.path
                              .split(Platform.pathSeparator)
                              .last;
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.folder),
                            ),
                            title: Text(
                              folderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => loadAllContentOfPath(folder.path),
                          );
                        },
                        childCount: folderData.length,
                      ),
                    ),
                  ],
                  if (fileData.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(left: 12, top: 12),
                        child: Text(
                          "Files",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.indigoAccent,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final file = fileData[index];
                          final fileName = file.path
                              .split(Platform.pathSeparator)
                              .last;
                          return ListTile(
                            leading: const Icon(
                              Icons.insert_drive_file,
                              color: Colors.blueGrey,
                            ),
                            title: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AlertDialog(
                                  title: Text("Invalid operation"),
                                  content: Text("You are in selection mode."),
                                ),
                              );
                            },
                          );
                        },
                        childCount: fileData.length,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8.0,
                left: 24.0,
                right: 24.0,
                top: 14.0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: () async {
                    final shouldPop = await _showProgressDialog(
                      context,
                          (onProgress) async {
                        if (widget.isSingleOperation &&
                            widget.selectedSinglePath != null) {
                          await FileOperations().pasteFileToDestination(
                            widget.isCopy,
                            currentPath,
                            widget.selectedSinglePath!,
                            onProgress: onProgress,
                          );
                        } else if (widget.selectedPaths != null &&
                            widget.selectedPaths!.isNotEmpty) {
                          final paths = widget.selectedPaths!.toList();
                          int totalSize = 0;
                          for (var path in paths) {
                            totalSize += await FileOperations().getEntitySize(path);
                          }
                          int copied = 0;
                          for (var path in paths) {
                            await FileOperations().pasteFileToDestination(
                              widget.isCopy,
                              currentPath,
                              path,
                              onProgress: (progress) {
                                FileOperations().getEntitySize(path).then((size) {
                                  onProgress(
                                    ((copied + (progress * size)) / totalSize)
                                        .clamp(0, 1),
                                  );
                                });
                              },
                            );
                            copied += await FileOperations().getEntitySize(path);
                          }
                          onProgress(1.0);
                          widget.selectedPaths!.clear();
                        }
                      },
                    );

                    if (shouldPop && mounted) {
                      Navigator.of(context).pop(); // Close the bottom sheet
                    }
                  },
                  child: const Text(
                    "Paste Here",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
