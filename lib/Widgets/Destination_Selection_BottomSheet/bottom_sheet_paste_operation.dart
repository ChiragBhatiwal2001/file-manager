import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Services/path_loading_operations.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'package:file_manager/Utils/constant.dart';

import 'file_list_widget.dart';
import 'folder_list_widget.dart';
import 'paste_sheet_header.dart';
import 'paste_button.dart';
import 'show_progress_dialog.dart';

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
  State<BottomSheetForPasteOperation> createState() =>
      _BottomSheetForPasteOperationState();
}

class _BottomSheetForPasteOperationState
    extends State<BottomSheetForPasteOperation> {
  late String currentPath;
  bool isLoading = false;
  List<FileSystemEntity> folders = [];
  List<FileSystemEntity> files = [];

  @override
  void initState() {
    super.initState();
    currentPath = Constant.internalPath!;
    _loadContent(currentPath);
  }

  Future<void> _loadContent(String path) async {
    setState(() => isLoading = true);
    final data = await compute(PathLoadingOperations.loadContentIsolate, path);
    setState(() {
      currentPath = path;
      folders = data.folders;
      files = data.files;
      isLoading = false;
    });
  }

  Future<void> _goBack() async {
    final data = await PathLoadingOperations.goBackToParentPath(
      context,
      currentPath,
    );
    if (data != null) {
      setState(() {
        currentPath = Directory(currentPath).parent.path;
        folders = data.folders;
        files = data.files;
      });
    }
  }

  Future<void> _createFolder() {
    return addFolderDialog(
      context: context,
      parentPath: currentPath,
      onSuccess: () => _loadContent(currentPath),
    );
  }

  Future<void> _handlePaste() async {
    final isSameDirectory =
        widget.isSingleOperation &&
        widget.selectedSinglePath != null &&
        Directory(widget.selectedSinglePath!).parent.path == currentPath;

    final isSameMulti =
        widget.selectedPaths != null &&
        widget.selectedPaths!.every(
          (e) => Directory(e).parent.path == currentPath,
        );

    if (isSameDirectory || isSameMulti) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Invalid Operation"),
          content: Text("You can't paste into the same directory."),
        ),
      );
      return;
    }

    final rootContext = Navigator.of(context, rootNavigator: true).context;

    await showProgressDialog(
      context: rootContext,
      operation: (onProgress) async {
        if (widget.isSingleOperation && widget.selectedSinglePath != null) {
          await FileOperations().pasteFileToDestination(
            widget.isCopy,
            currentPath,
            widget.selectedSinglePath!,
            onProgress: onProgress,
          );
        } else if (widget.selectedPaths != null &&
            widget.selectedPaths!.isNotEmpty) {
          final paths = widget.selectedPaths!.toList();
          int totalSize = 0;
          for (var path in paths) {
            totalSize += await FileOperations().getEntitySize(path);
          }

          int copied = 0;
          for (var path in paths) {
            await FileOperations().pasteFileToDestination(
              widget.isCopy,
              currentPath,
              path,
              onProgress: (progress) async {
                final size = await FileOperations().getEntitySize(path);
                onProgress(
                  ((copied + (progress * size)) / totalSize).clamp(0, 1),
                );
              },
            );
            copied += await FileOperations().getEntitySize(path);
          }

          onProgress(1.0);
          widget.selectedPaths!.clear();
        }
      },
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1,
      builder: (context, scrollController) {
        if (isLoading) return const Center(child: CircularProgressIndicator());

        return Column(
          children: [
            PasteSheetHeader(
              currentPath: currentPath,
              onBack: _goBack,
              onCreate: _createFolder,
            ),
            BreadcrumbWidget(path: currentPath, loadContent: _loadContent),
            if (folders.isEmpty && files.isEmpty)
              const Expanded(child: ScreenEmptyWidget())
            else
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    if (folders.isNotEmpty)
                      FolderListWidget(folders: folders, onTap: _loadContent),
                    if (files.isNotEmpty) FileListWidget(files: files),
                  ],
                ),
              ),
            PasteButton(onPressed: _handlePaste),
          ],
        );
      },
    );
  }
}
