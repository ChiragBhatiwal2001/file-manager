import 'dart:io';
import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Services/path_loading_operations.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/list_widget.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

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
  State<BottomSheetForPasteOperation> createState() {
    return _BottomSheetForPasteOperationState();
  }
}

class _BottomSheetForPasteOperationState
    extends State<BottomSheetForPasteOperation> {
  String? internalStorage;
  late String currentPath;
  bool isLoading = false;
  List<FileSystemEntity> folderData = [];
  List<FileSystemEntity> fileData = [];

  @override
  void initState() {
    super.initState();
    internalStorage = Constant.internalPath;
    currentPath = internalStorage!;
    loadAllContentOfPath(internalStorage!);
  }

  Future<void> loadAllContentOfPath(path) async {
    setState(() {
      isLoading = true;
    });
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

    if (data == null) {
      return;
    }

    String parentPath = Directory(path).parent.path;

    setState(() {
      currentPath = parentPath;
      folderData = data.folders;
      fileData = data.files;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = folderData.isEmpty && fileData.isEmpty;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1,
      builder: (context, scrollController) {
        if (isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    goBack(currentPath);
                  },
                  child: Text("Back", style: TextStyle(fontSize: 16)),
                ),
                Spacer(),
                Text(
                  "${currentPath.split("/").last == "0" ? "All Files" : currentPath.split("/").last}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    addFolderDialog(
                      context: context,
                      parentPath: currentPath,
                      onSuccess: () {
                        loadAllContentOfPath(currentPath);
                      },
                    );
                  },
                  child: Text("Create", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            BreadcrumbWidget(
              path: internalStorage!,
              loadContent: loadAllContentOfPath,
            ),

            isEmpty
                ? Expanded(child: ScreenEmptyWidget())
                : Expanded(
                    child: ListView.builder(
                      itemCount:
                          (folderData.isNotEmpty ? folderData.length + 1 : 0) +
                          (fileData.isNotEmpty ? fileData.length + 1 : 0),
                      itemBuilder: (context, index) {
                        int folderHeaderIndex = 0;
                        int fileHeaderIndex = folderData.isNotEmpty
                            ? folderData.length + 1
                            : 0;

                        if (index == folderHeaderIndex &&
                            folderData.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              left: 12.0,
                              top: 8,
                              bottom: 0,
                            ),
                            child: Text(
                              "Folders",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.indigoAccent,
                              ),
                            ),
                          );
                        } else if (index > folderHeaderIndex &&
                            index < fileHeaderIndex) {
                          final folder =
                              folderData[index -
                                  1]; // -1 because of folder heading

                          return ListWidget(
                            storageFile: folder,
                            onTap: () {
                              loadAllContentOfPath(folder.path);
                            },
                          );
                        } else if (index == fileHeaderIndex &&
                            fileData.isNotEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
                              left: 12.0,
                              bottom: 0.0,
                            ),
                            child: Text(
                              "Files",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.indigoAccent,
                              ),
                            ),
                          );
                        } else {
                          final file =
                              fileData[index -
                                  fileHeaderIndex -
                                  1]; // -1 for file heading

                          return ListWidget(
                            storageFile: file,
                            onTap: () {
                              OpenFilex.open(file.path);
                            },
                          );
                        }
                      },
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
                  onPressed: () async {
                    if (widget.isSingleOperation &&
                        widget.selectedSinglePath != null) {
                      await FileOperations().pasteFileToDestination(
                        widget.isCopy,
                        currentPath,
                        widget.selectedSinglePath!,
                      );
                    } else if (widget.selectedPaths != null &&
                        widget.selectedPaths!.isNotEmpty) {
                      for (var path in widget.selectedPaths!) {
                        await FileOperations().pasteFileToDestination(
                          widget.isCopy,
                          currentPath,
                          path,
                        );
                      }
                      widget.selectedPaths!.clear();
                    }
                    if (mounted) {
                      Navigator.pop(context); // Dismiss the bottom sheet first
                      await Future.delayed(Duration(milliseconds: 200));
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text("Operation Finished Successfully"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dialog
                                },
                                child: Text("OK"),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  child: Text(
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
