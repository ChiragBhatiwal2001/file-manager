import 'dart:ffi';
import 'dart:io';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/popup_menu_widget.dart';
import 'package:flutter/material.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key, this.path = "/storage/emulated/0/"});

  final String path;

  @override
  State<FileExplorerScreen> createState() {
    return _FileExplorerScreenState();
  }
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  late String currentPath;
  List<FileSystemEntity> folderData = [];

  @override
  void initState() {
    super.initState();

    currentPath = widget.path;
    _loadContent(currentPath);
  }

  void _loadContent(String path) async {
    try {
      final data = await Directory(path).list().toList();
      setState(() {
        currentPath = path;
        folderData = data;
      });
    } catch (e) {
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
    String rootPath = "/storage/emulated/0/";

    if (currentPath == rootPath) {
      Navigator.pop(context);
      return;
    }

    String parentPath = Directory(currentPath).parent.path;
    if (parentPath != currentPath) {
      _loadContent(parentPath);
    }
  }

  void _addContent(String value){
     print(value);
  }

  @override
  Widget build(BuildContext context) {
    String currentFolderName = currentPath == "/storage/emulated/0/"
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
          PopupMenuWidget(popupList: ["Folder","File"],addContent: _addContent,),
          IconButton(onPressed: () {}, icon: Icon(Icons.search),padding: EdgeInsets.zero,),
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
          folderData.isEmpty
              ? Expanded(
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
              : Expanded(
                  child: ListView.builder(
                    itemCount: folderData.length,
                    itemBuilder: (context, index) {
                      final file = folderData[index];
                      final fileName = file.path.split("/").last;
                      final isDir = FileSystemEntity.isDirectorySync(file.path);
                      return ListTile(
                        leading: Icon(
                          isDir ? Icons.folder : Icons.insert_drive_file,
                        ),
                        title: Text(fileName),
                        onTap: () {
                          _navigateToFolder(file.path);
                        },
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
