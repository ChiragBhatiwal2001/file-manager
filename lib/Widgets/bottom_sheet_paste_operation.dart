import 'dart:io';

import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/list_widget.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class BottomSheetForPasteOperation extends StatefulWidget {
  const BottomSheetForPasteOperation({super.key, required this.selectedPaths,required this.isCopy});

  final Set<String> selectedPaths;
  final bool isCopy;

  @override
  State<BottomSheetForPasteOperation> createState() {
    return _BottomSheetForPasteOperationState();
  }
}

class _BottomSheetForPasteOperationState
    extends State<BottomSheetForPasteOperation> {
  String? internalStorage;
  late String currentPath;
  final _newFolderTextController = TextEditingController();
  bool _isLoading = false;
  List<FileSystemEntity> folderData = [];
  List<FileSystemEntity> fileData = [];

  @override
  void initState() {
    super.initState();
    internalStorage = Constant.internalPath;
    currentPath = internalStorage!;
    _loadContent(internalStorage!);
  }

  void _loadContent(String path) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await Directory(path).list().toList();
      setState(() {
        currentPath = path;
        folderData = data.whereType<Directory>().toList();
        fileData = data.whereType<File>().toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), duration: Duration(seconds: 5)),
        );
      }
    }
  }

  void _navigateToFolder(String path) {
    _loadContent(path);
  }

  void _goBackToParentPath() {
    String rootPath = internalStorage!;
    String parentPath = Directory(currentPath).parent.path;

    if (currentPath == rootPath) {
      Navigator.pop(context);
      return;
    }

    if (!parentPath.startsWith(rootPath)) {
      Navigator.pop(context);
      return;
    }
    _loadContent(parentPath);
  }

  void _addContent() {
    showAddFolderDialog(
      context: context,
      controller: _newFolderTextController,
      onCreate: () async {
        final folderName = _newFolderTextController.text;
        final path = "$currentPath/$folderName";
        final dir = Directory(path);
        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
        if (context.mounted) {
          Navigator.pop(context);
        }
        _newFolderTextController.clear();
        _loadContent(currentPath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1,
      builder: (context, scrollController) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    _goBackToParentPath();
                  },
                  child: Text("Back", style: TextStyle(fontSize: 16)),
                ),
                Spacer(),
                Text(
                  "Select Destination",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    _addContent();
                  },
                  child: Text("Create", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            BreadcrumbWidget(path: internalStorage!, loadContent: _loadContent),
            Expanded(
              child: ListView.builder(
                itemCount:
                    (folderData.isNotEmpty ? folderData.length + 1 : 0) +
                    (fileData.isNotEmpty ? fileData.length + 1 : 0),
                itemBuilder: (context, index) {
                  int folderHeaderIndex = 0;
                  int fileHeaderIndex = folderData.isNotEmpty
                      ? folderData.length + 1
                      : 0;

                  if (index == folderHeaderIndex && folderData.isNotEmpty) {
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
                        folderData[index - 1]; // -1 because of folder heading

                    return ListWidget(
                      storageFile: folder,
                      onTap: () {
                        _navigateToFolder(folder.path);
                      },
                    );
                  } else if (index == fileHeaderIndex && fileData.isNotEmpty) {
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
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ElevatedButton(
                onPressed: () async {
                  print("I am Clicked");
                  print("Selected paths length: ${widget.selectedPaths.length}");
                  for (var path in widget.selectedPaths) {
                    print("I am In Loop");
                    await FileOperations().pasteFileToDestination(
                      widget.isCopy,
                      currentPath,
                      path,
                    );
                    print("Current path is $currentPath and where we want to move is $path");
                  }

                 Navigator.pop(context);
                  widget.selectedPaths.clear();
                },
                child: Text("Paste Here", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        );
      },
    );
  }
}