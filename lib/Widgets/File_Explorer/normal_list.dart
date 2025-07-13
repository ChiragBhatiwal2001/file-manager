import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_manager/Widgets/File_Explorer/file_list_tile.dart';
import 'package:file_manager/Widgets/File_Explorer/folder_list_tile.dart';

class NormalExplorerListView extends StatelessWidget {
  final List<FileSystemEntity> folders;
  final List<FileSystemEntity> files;

  const NormalExplorerListView({
    super.key,
    required this.folders,
    required this.files,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = (folders.isNotEmpty ? folders.length + 1 : 0) +
        (files.isNotEmpty ? files.length + 1 : 0);

    return ListView.builder(
      itemCount: totalCount,
      itemBuilder: (context, index) {
        final folderHeaderIndex = 0;
        final fileHeaderIndex = folders.isNotEmpty ? folders.length + 1 : 0;

        if (index == folderHeaderIndex && folders.isNotEmpty) {
          return const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8, bottom: 0),
            child: Text("Folders", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        } else if (index > folderHeaderIndex && index < fileHeaderIndex) {
          final folderPath = folders[index - 1].path;
          return FolderListTile(path: folderPath);
        } else if (index == fileHeaderIndex && files.isNotEmpty) {
          return const Padding(
            padding: EdgeInsets.only(left: 12.0, top: 8, bottom: 0),
            child: Text("Files", style: TextStyle(fontWeight: FontWeight.bold)),
          );
        } else {
          final filePath = files[index - fileHeaderIndex - 1].path;
          return FileListTile(
            key: ValueKey('$filePath-$index'),
            path: filePath,
          );
        }
      },
    );
  }
}
