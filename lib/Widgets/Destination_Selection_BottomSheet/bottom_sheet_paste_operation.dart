import 'package:file_manager/Helpers/get_unique_name.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/file_list_widget.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/folder_list_widget.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/paste_button.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/paste_sheet_header.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/show_progress_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/screen_empty_widget.dart';
import 'package:file_manager/Widgets/breadcrumb_widget.dart';
import 'package:file_manager/Helpers/add_folder_dialog.dart';
import 'package:file_manager/Services/path_loading_operations.dart';
import 'package:file_manager/Services/file_operations.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;

class BottomSheetForPasteOperation extends ConsumerStatefulWidget {
  final Set<String>? selectedPaths;
  final bool isCopy;

  const BottomSheetForPasteOperation({
    super.key,
    this.selectedPaths,
    required this.isCopy,
  });

  @override
  ConsumerState<BottomSheetForPasteOperation> createState() =>
      _BottomSheetForPasteOperationState();
}

class _BottomSheetForPasteOperationState
    extends ConsumerState<BottomSheetForPasteOperation> {
  late String currentPath;
  bool isLoading = false;
  bool _isPasting = false;
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
    final data = await compute(PathLoadingOperations.loadContent, path);
    setState(() {
      currentPath = path;
      folders = data.folders;
      files = data.files;
      isLoading = false;
    });
  }

  Future<void> _goBack() async {
    final parentPath = PathLoadingOperations.goBackToParentPath(currentPath);
    if (parentPath == null) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }

    await _loadContent(parentPath);
  }

  Future<void> _createFolder() => addFolderDialog(
    context: context,
    parentPath: currentPath,
    onSuccess: () => _loadContent(currentPath),
  );

  Future<void> _handlePaste() async {
    bool didSomething = false;
    if (_isPasting) return;
    setState(() => _isPasting = true);

    final rootContext = Navigator.of(context, rootNavigator: true).context;

    if (widget.selectedPaths == null || widget.selectedPaths!.isEmpty) {
      Fluttertoast.showToast(msg: "No files selected to paste.");
      return;
    }

    if (!widget.isCopy) {
      final isInvalid = widget.selectedPaths!.any((path) => p.dirname(path) == currentPath);
      if (isInvalid) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Invalid Operation"),
            content: const Text("Cannot move files or folders into the same directory."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        setState(() => _isPasting = false);
        return;
      }
    }


    await showProgressDialog(
      context: rootContext,
      operation: (onProgress) async {
        try {
          final fileOps = FileOperations();
          final resolvedTargets = <String>[];
          for (final path in widget.selectedPaths!) {
            final name = p.basename(path);
            String destPath = p.join(currentPath, name);

            if (await FileSystemEntity.type(destPath) !=
                FileSystemEntityType.notFound) {
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Name Conflict"),
                  content: Text(
                    "File or Folder name \"$name\" is already present.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, "skip"),
                      child: const Text("Skip"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, "keepBoth"),
                      child: const Text("Keep Both"),
                    ),
                  ],
                ),
              );

              if (result == "keepBoth") {
                destPath = await getUniqueDestinationPath(destPath);
                resolvedTargets.add(destPath);
              } else {
                continue;
              }
            } else {
              resolvedTargets.add(destPath);
            }
          }

          if (resolvedTargets.isEmpty) {
            Fluttertoast.showToast(
              msg: "${widget.isCopy ? 'Copy' : 'Move'} operation Skipped",
            );
            return;
          }

          await fileOps.pasteMultipleFilesInBackground(
            paths: widget.selectedPaths!.toList(),
            resolvedPaths: resolvedTargets,
            destination: currentPath,
            isCopy: widget.isCopy,
            onProgress: onProgress,
          );
          widget.selectedPaths!.clear();
          didSomething = true;
          Fluttertoast.showToast(
            msg: "${widget.isCopy ? 'Copy' : 'Move'} operation completed",
          );
        } catch (e) {
          if (context.mounted) {
            await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Paste Error"),
                content: Text("An error occurred during paste:\n$e"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        }
      },
    );
    if (!mounted) return;

    if (didSomething) {
      Navigator.pop(context, currentPath);
    } else {
      Navigator.pop(context);
    }
    setState(() => _isPasting = false);
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
            BreadcrumbWidget(
              path: currentPath,
              currentPath: currentPath,
              loadContent: _loadContent,
            ),
            if (folders.isEmpty && files.isEmpty)
              const Expanded(child: ScreenEmptyWidget())
            else
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    if (folders.isNotEmpty)
                      FolderListWidget(
                        folders: folders,
                        selectedPaths: widget.selectedPaths ?? {},
                        onTap: _loadContent,
                      ),
                    if (files.isNotEmpty)
                      FileListWidget(
                        files: files,
                        selectedPaths: widget.selectedPaths ?? {},
                      ),
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
