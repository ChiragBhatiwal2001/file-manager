import 'package:file_manager/Providers/manual_drag_mode_notifier.dart';
import 'package:file_manager/Providers/selction_notifier.dart';
import 'package:file_manager/Providers/view_toggle_notifier.dart';
import 'package:file_manager/Utils/constant.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_appbar.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_body.dart';
import 'package:file_manager/Widgets/File_Explorer/file_explorer_grid_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/Providers/file_explorer_notifier.dart';

class FileExplorerScreen extends ConsumerStatefulWidget {
  const FileExplorerScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  ConsumerState<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends ConsumerState<FileExplorerScreen> {

  String? _previousViewMode;

  @override
  void initState() {
    super.initState();
    final initPath = widget.initialPath ?? Constant.internalPath!;
    Future.microtask(() {
      ref.read(currentPathProvider.notifier).state = initPath;
      ref.read(fileExplorerProvider.notifier).loadAllContentOfPath(initPath);
    });
  }


  @override
  Widget build(BuildContext context) {
    final explorerState = ref.watch(fileExplorerProvider);
    final selectionState = ref.watch(selectionProvider);
    final selectionNotifier = ref.read(selectionProvider.notifier);
    final viewMode = ref.watch(fileViewModeProvider);
    final viewModeNotifier = ref.read(fileViewModeProvider.notifier);
    final isInDragMode = ref.watch(manualDragModeProvider);

    if (isInDragMode && viewMode == "Grid View") {
      _previousViewMode = "Grid View";
      viewModeNotifier.setMode("List View");
    } else if (!isInDragMode && _previousViewMode == "Grid View") {
      viewModeNotifier.setMode("Grid View");
      _previousViewMode = null;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (selectionState.isSelectionMode) {
          selectionNotifier.clearSelection();
          return;
        }
        if (!didPop && explorerState.currentPath != Constant.internalPath) {
          if (!mounted) return;
          final notifier = ref.read(fileExplorerProvider.notifier);
          await notifier.goBack(context);
        } else if (!didPop &&
            explorerState.currentPath == Constant.internalPath) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(104.0),
          child: FileExplorerAppBar(
            currentPath: explorerState.currentPath,
          ),
        ),
        body: explorerState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : viewMode == "List View"
            ? FileExplorerBody()
            : FileExplorerGridBody(providerInstance: fileExplorerProvider),
        floatingActionButton: isInDragMode
            ? FloatingActionButton(
          onPressed: () {
            ref.read(manualDragModeProvider.notifier).state = false;

            final path = ref.read(currentPathProvider);
            ref.read(fileExplorerProvider.notifier).loadAllContentOfPath(path);
          },
          child: Icon(Icons.clear),
        )
            : null,
      ),
    );
  }
}
