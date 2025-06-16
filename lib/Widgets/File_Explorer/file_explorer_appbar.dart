import 'dart:io';

import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Screens/search_screen.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/popup_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class FileExplorerAppBar extends StatelessWidget {
  final String path;
  final void Function(String path) handleBreadCrumbTap;
  final void Function(String path) goBack;
  final void Function(String path) loadNewContent;
  final String? currentSortValue;
  final void Function(String sortValue)? onSortChanged;

  const FileExplorerAppBar({
    super.key,
    required this.path,
    required this.handleBreadCrumbTap,
    required this.goBack,
    required this.loadNewContent,
    this.currentSortValue,
    this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final String headingPath = path == Constant.internalPath
        ? "All Files"
        : p.basename(path);

    void showAddFolderDialog(){
      addFolderDialog(context: context, parentPath: path, onSuccess: ()=>loadNewContent(path));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: IconButton(
            onPressed: () => goBack(path),
            icon: const Icon(Icons.arrow_back),
          ),
          titleSpacing: 0,
          title: Text(
            headingPath,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 2,
          actions: [
            IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  builder: (context) => SearchScreen(Constant.internalPath),
                );
              },
              icon: Icon(Icons.search),
            ),
            PopupMenuWidget(
              showAddFolderDialog: showAddFolderDialog,
              popupList: ["Create Folder", "Sorting"],
              currentSortValue: currentSortValue,
              onSortChanged: onSortChanged,
            ),
          ],
        ),
        Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: BreadcrumbWidget(path: path, loadContent: handleBreadCrumbTap),
        ),
      ],
    );
  }
}