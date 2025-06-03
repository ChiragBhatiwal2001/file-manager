import 'dart:io';
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
    String parentPath = Directory(currentPath).parent.path;
    if (parentPath != currentPath) {
      _loadContent(parentPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(icon: Icon(Icons.arrow_back),onPressed: (){
            _goBackToParentPath();
          },),
        ),
        body: ListView.builder(
          itemCount: folderData.length,
          itemBuilder: (context, index) {
            final file = folderData[index];
            final fileName = file.path.split("/").last;
            final isDir = FileSystemEntity.isDirectorySync(file.path);
            return ListTile(
              leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
              title: Text(fileName),
              onTap: () {
                _navigateToFolder(file.path);
              },
            );
          },
        ),
      ),
    );
  }
}