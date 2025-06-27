import 'package:file_manager/Helpers/get_unique_name.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart' as p;

class BottomSheetForPasteOperation extends ConsumerStatefulWidget {
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
    if (_isPasting) return;
    setState(() => _isPasting = true);

    final rootContext = Navigator.of(context, rootNavigator: true).context;

    await showProgressDialog(
      context: rootContext,
      operation: (onProgress) async {
        try {
          final fileOps = FileOperations();

          if (widget.selectedSinglePath != null) {
            String destFileName = p.basename(widget.selectedSinglePath!);
            String destPath = p.join(currentPath, destFileName);
            if (await File(destPath).exists() || await Directory(destPath).exists()) {
              destPath = await getUniqueDestinationPath(destPath);
              destFileName = p.basename(destPath);
            }
            await fileOps.pasteFileToDestination(
              widget.isCopy,
              p.dirname(destPath),
              widget.selectedSinglePath!,
              onProgress: onProgress,
              newName: destFileName
            );
          } else if (widget.selectedPaths != null &&
              widget.selectedPaths!.isNotEmpty) {

            if (widget.selectedPaths!.length == 1) {
              String src = widget.selectedPaths!.first;
              String destPath = p.join(currentPath, p.basename(src));
              if (await FileSystemEntity.type(destPath) != FileSystemEntityType.notFound) {
                destPath = await getUniqueDestinationPath(destPath);
              }
              await fileOps.pasteFileToDestination(
                widget.isCopy,
                p.dirname(destPath),
                src,
                onProgress: onProgress,
              );
            } else {
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
    if (!mounted) return;

    Fluttertoast.showToast(
    msg: "${widget.isCopy ? 'Copy' : 'Move'} operation completed",
    );
    Navigator.pop(context,currentPath);
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
            BreadcrumbWidget(path: currentPath,currentPath: currentPath, loadContent: _loadContent),
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
