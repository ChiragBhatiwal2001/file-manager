import 'dart:io';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/popup_menu_widget.dart';
import 'package:flutter/material.dart';

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
    // TODO: implement dispose
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
        folderData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), duration: Duration(seconds: 5)),
      );
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Add New Folder"),
          content: TextField(
            controller: _newFolderTextController,
            decoration: InputDecoration(
              label: Text("Folder Name"),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5.0),
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final folderName = _newFolderTextController.text;
                final path = "$currentPath/$folderName";
                final dir = Directory(path);
                if (!dir.existsSync()) {
                  await dir.create(recursive: true);
                }
                Navigator.pop(context);
                _newFolderTextController.clear();
                _loadContent(currentPath);
              },
              child: Text("Create"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRenameDialog() async {
    final oldPath = selectedPath.first;
    final isDir = FileSystemEntity.isDirectorySync(oldPath);
    final oldName = oldPath.split("/").last;
    final _renameTextController = TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isDir ? "Rename Folder" : "Rename File"),
          content: TextField(
            controller: _renameTextController,
            decoration: InputDecoration(
              label: Text("Name"),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final newName = _renameTextController.text.trim();
                if (newName.isEmpty || newName == oldName) return;

                final parentDir = Directory(oldPath).parent.path;
                final newPath = "$parentDir/$newName";

                try {
                  final entity = isDir ? Directory(oldPath) : File(oldPath);
                  await entity.rename(newPath);

                  setState(() {
                    selectedPath.clear();
                    isSelected = false;
                  });
                  Navigator.of(context).pop();
                  _loadContent(currentPath); // Refresh list
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Rename failed: ${e.toString()}")),
                  );
                }
              },
              child: Text("Confirm"),
            ),
          ],
        );
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
      body: Column(
        children: [
          BreadcrumbWidget(
            path: currentPath,
            loadContent: (path) {
              _navigateToFolder(path);
            },
          ),
          if (_isLoading)
            Center()
          else if (folderData.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_off, size: 175.0),
                    SizedBox(height: 10),
                    Text(
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
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: folderData.length,
                itemBuilder: (context, index){
                  final file = folderData[index];
                  final fileName = file.path.split("/").last;
                  final isDir = FileSystemEntity.isDirectorySync(file.path);
                  final isChecked = selectedPath.contains(file.path);
                  return ListTile(
                    leading: Icon(
                      isDir ? Icons.folder : Icons.insert_drive_file,
                    ),
                    title: Text(fileName),
                    trailing: isSelected
                        ? Checkbox(
                            value: isChecked,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedPath.add(file.path);
                                } else {
                                  selectedPath.remove(file.path);
                                }
                              });
                            },
                          )
                        : null,
                    onLongPress: () {
                      setState(() {
                        isSelected = true;
                        selectedPath.add(folderData[index].path);
                      });
                    },
                    onTap: () {
                      isDir
                          ? _navigateToFolder(file.path)
                          : print("File Found");
                    },
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: isSelected == true
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedPath.length <= 1)
                    IconButton(
                      onPressed: () {
                        _showRenameDialog();
                      },
                      icon: Icon(Icons.drive_file_rename_outline),
                    ),
                  IconButton(
                    onPressed: () async {
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
                    icon: Icon(Icons.copy),
                  ),
                  SizedBox(width: 10),
                  IconButton(
                    onPressed: () async {
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
                    icon: Icon(Icons.drive_file_move),
                  ),
                  IconButton(
                    onPressed: () {
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
                    icon: Icon(Icons.delete),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}