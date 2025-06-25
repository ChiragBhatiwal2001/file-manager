import 'dart:io';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Utils/restricted_files.dart';
import 'package:flutter/material.dart';

class DirectoryContent {
  final List<Directory> folders;
  final List<File> files;

  DirectoryContent(this.folders, this.files);
}

class PathLoadingOperations {
  static final _internalStoragePath = Constant.internalPath;

  static Future<DirectoryContent> loadContent(String path) async {
    try {
      final data = await Directory(path).list().toList();
      // final folderData = data.whereType<Directory>().toList();
      // final fileData = data.whereType<File>().toList();
      final visibleEntities = FileFilterUtils.filterVisible(data);
      final folderData = visibleEntities.whereType<Directory>().toList();
      final fileData = visibleEntities.whereType<File>().toList();
      return DirectoryContent(folderData, fileData);
    } catch (e) {
      return DirectoryContent([], []);
    }
  }

  static Future<DirectoryContent> loadContentIsolate(String path) async {
    return await loadContent(path);
  }

  static String? goBackToParentPath(String currentPath) {
    final rootPath = _internalStoragePath!;
    final parentPath = Directory(currentPath).parent.path;

    if (currentPath == rootPath || !parentPath.startsWith(rootPath)) {
      return null;
    }
    return parentPath;
  }

}
