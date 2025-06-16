import 'dart:io';

import 'package:file_manager/Services/path_loading_operations.dart';
import 'package:file_manager/Services/shared_preference.dart';
import 'package:file_manager/Services/sorting_operation.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_appbar.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_body.dart';
import 'package:flutter/material.dart';

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key, required this.path});

  final String path;

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  List<FileSystemEntity> folderData = [];
  List<FileSystemEntity> fileData = [];
  late String currentPath;
  bool isLoading = false;
  String currentSortValue = "name-asc";

  void loadAllContentOfPath(path) async {
    setState(() {
      isLoading = true;
    });
    final data = await PathLoadingOperations.loadContent(path);

    final sorting = SortingOperation(
      filterItem: currentSortValue,
      folderData: data.folders,
      fileData: data.files,
    );
    sorting.sortFileAndFolder();

    setState(() {
      currentPath = path;
      folderData = sorting.folderData;
      fileData = sorting.fileData;
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

  void _initSortValue() async {
    final prefs = SharedPrefsService.instance;
    await prefs.init();
    final savedSort = prefs.getString("sort-preference");
    setState(() {
      currentSortValue = savedSort ?? "name-asc";
      currentPath = widget.path;
    });
    loadAllContentOfPath(currentPath);
  }

  void onSortChanged(String sortValue) async {
    setState(() {
      currentSortValue = sortValue;
    });
    await SharedPrefsService.instance.setString("sort-preference", sortValue);
    loadAllContentOfPath(currentPath);
  }

  @override
  void initState() {
    super.initState();
    _initSortValue();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Appbar widget from widgets folder (file - file_explorer_appbar.dart)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(104.0),
        child: FileExplorerAppBar(
          path: currentPath,
          handleBreadCrumbTap: loadAllContentOfPath,
          goBack: goBack,
          loadNewContent: loadAllContentOfPath,
          currentSortValue: currentSortValue,
          onSortChanged: onSortChanged,
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : FileExplorerBody(folderData, fileData, loadAllContentOfPath),
    );
  }
}