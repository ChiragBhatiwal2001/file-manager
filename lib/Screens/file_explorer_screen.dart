import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Helpers/rename_dialog.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Widgets/bottom_bar_widget.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/popup_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Widgets/list_widget.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key, required this.path});

  final String path;

  @override
  State<FileExplorerScreen> createState() {
    return _FileExplorerScreenState();
  }
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  late String currentPath;
  List<FileSystemEntity> folderData = [];
  List<FileSystemEntity> fileData = [];
  final _newFolderTextController = TextEditingController();
  bool isSelected = false;
  bool _isLoading = false;
  Set<String> selectedPath = {};

  @override
  void initState() {
    super.initState();
    currentPath = widget.path;
    _loadContent(currentPath);
  }

  @override
  void dispose() {
    super.dispose();
    _newFolderTextController.dispose();
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
    String rootPath = widget.path;
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

  Future<void> _showRenameDialog() async {
    final oldPath = selectedPath.first;
    await renameDialogBox(
      context: context,
      oldPath: oldPath,
      onSuccess: () {
        setState(() {
          selectedPath.clear();
          isSelected = false;
        });
        _loadContent(currentPath);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentFolderName = currentPath == widget.path
        ? "All Files"
        : currentPath.split("/").last;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentFolderName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            _goBackToParentPath();
          },
        ),
        actions: [
          PopupMenuWidget(
            popupList: ["Create Folder"],
            addContent: _addContent,
          ),
          if (isSelected)
            TextButton(
              onPressed: () {
                setState(() {
                  isSelected = false;
                  selectedPath.clear();
                });
              },
              child: Text(
                "Cancel",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BreadcrumbWidget(
                  path: currentPath,
                  loadContent: (path) {
                    _navigateToFolder(path);
                  },
                ),
                if (folderData.isEmpty && fileData.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_off, size: 175.0),
                          const SizedBox(height: 10),
                          const Text(
                            "Files Not Found",
                            style: TextStyle(
                              wordSpacing: 1,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else
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
                          final isChecked = selectedPath.contains(folder.path);

                          return ListWidget(
                            storageFile: folder,
                            onTap: () {
                              _navigateToFolder(folder.path);
                            },
                            onLongPress: () {
                              setState(() {
                                isSelected = true;
                                selectedPath.add(folder.path);
                              });
                            },
                            onCheckboxChanged: (value) {
                              setState(() {
                                value == true
                                    ? selectedPath.add(folder.path)
                                    : selectedPath.remove(folder.path);
                              });
                            },
                            isChecked: isChecked,
                            isSelected: isSelected,
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
                          final isChecked = selectedPath.contains(file.path);

                          return ListWidget(
                            storageFile: file,
                            onTap: () {
                              if (isSelected) {
                                setState(() {
                                  isChecked
                                      ? selectedPath.remove(file.path)
                                      : selectedPath.add(file.path);
                                });
                              } else {
                                OpenFilex.open(file.path);
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                isSelected = true;
                                selectedPath.add(file.path);
                              });
                            },
                            onCheckboxChanged: (value) {
                              setState(() {
                                value == true
                                    ? selectedPath.add(file.path)
                                    : selectedPath.remove(file.path);
                              });
                            },
                            isChecked: isChecked,
                            isSelected: isSelected,
                          );
                        }
                      },
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: isSelected
          ? BottomBarWidget(
              isRenameEnabled: selectedPath.length <= 1,
              onRename: _showRenameDialog,
              onCopy: () async {
                setState(() {
                  isSelected = false;
                });
                for (var path in selectedPath) {
                  await FileOperations().pasteFileToDestination(
                    true,
                    currentPath,
                    path,
                  );
                }
                selectedPath.clear();
                _loadContent(currentPath);
              },
              onMove: () async {
                setState(() {
                  isSelected = false;
                });
                for (var path in selectedPath) {
                  await FileOperations().pasteFileToDestination(
                    false,
                    currentPath,
                    path,
                  );
                }
                selectedPath.clear();
                _loadContent(currentPath);
              },
              onDelete: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Do You Really Want To Delete?"),
                    duration: Duration(seconds: 5),
                    action: SnackBarAction(
                      label: "Yes",
                      onPressed: () async {
                        setState(() {
                          isSelected = false;
                        });
                        for (var path in selectedPath) {
                          await FileOperations().deleteOperation(path);
                        }
                        selectedPath.clear();
                        _loadContent(currentPath);
                      },
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }
}