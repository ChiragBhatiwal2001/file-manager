import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/file_list_widget.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/folder_list_widget.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/paste_button.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/paste_sheet_header.dart';
import 'package:file_manager/Widgets/Destination_Selection_BottomSheet/paste_worker.dart';
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
import 'dart:isolate';
import 'dart:async';

class BottomSheetForPasteOperation extends StatefulWidget {
  final Set<String>? selectedPaths;
  final String? selectedSinglePath;
  final bool isCopy;
  final bool isSingleOperation;

  const BottomSheetForPasteOperation({
    super.key,
    this.selectedPaths,
    this.selectedSinglePath,
    required this.isCopy,
    this.isSingleOperation = false,
  });

  @override
  State<BottomSheetForPasteOperation> createState() =>
      _BottomSheetForPasteOperationState();
}

class _BottomSheetForPasteOperationState
    extends State<BottomSheetForPasteOperation> {
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

  Future<void> _createFolder() => addFolderDialog(
    context: context,
    parentPath: currentPath,
    onSuccess: () => _loadContent(currentPath),
  );

  Future<void> _handlePaste() async {
    if (_isPasting) return;
    setState(() => _isPasting = true);

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
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("Invalid Operation"),
          content: Text("You can't paste into the same directory."),
        ),
      );
      setState(() => _isPasting = false);
      return;
    }

    final rootContext = Navigator.of(context, rootNavigator: true).context;

    await showProgressDialog(
      context: rootContext,
      operation: (onProgress) async {
        final fileOps = FileOperations();
        try {
          if (widget.isSingleOperation && widget.selectedSinglePath != null) {
            await fileOps.pasteFileToDestination(
              widget.isCopy,
              currentPath,
              widget.selectedSinglePath!,
              onProgress: onProgress,
            );
          } else if (widget.selectedPaths != null &&
              widget.selectedPaths!.isNotEmpty) {
            final receivePort = ReceivePort();
            await Isolate.spawn(pasteWorker, {
              'paths': widget.selectedPaths!.toList(),
              'destination': currentPath,
              'isCopy': widget.isCopy,
              'sendPort': receivePort.sendPort,
            });

            await for (var message in receivePort) {
              if (message is double) {
                onProgress(message);
              } else if (message == 'done') {
                receivePort.close();
                break;
              }
            }

            widget.selectedPaths!.clear();
          }
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

    if (mounted) Navigator.of(context).pop(true);
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
            BreadcrumbWidget(path: currentPath, loadContent: _loadContent),
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
